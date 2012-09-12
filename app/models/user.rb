require 'devise/strategies/base'
require 'devise'

module Devise
  module Strategies

    # Remember the user through the remember token. This strategy is responsible
    # to verify whether there is a cookie with the remember token, and to
    # recreate the user from this cookie if it exists. Must be called *before*
    # authenticatable.
    class OpenTableAuthenticatable < Authenticatable
      def authenticate!
        cookie_jar = validate_username_and_password(authentication_hash[:email], password)
        values = CGI::parse(cookie_jar.jar["opentable.com"]["/"]["uCke"].to_s) if cookie_jar

        uid = values['uCke'].join('').gsub(/uid\=/,'')
        uid = uid[0,uid.size-2]

        resource = mapping.to.find_for_authentication(:ot_id => uid)
        resource ||= mapping.to.find_for_authentication(authentication_hash)
        resource ||= mapping.to.new if resource.nil?

        if cookie_jar
          values = CGI::parse(cookie_jar.jar["opentable.com"]["/"]["uCke"].to_s)
          resource.name = "#{values['fn'].join('')} #{values['ln'].join('')}"
          resource.phone = "#{values['pn'].join('') if values['pn']}"
          resource.ot_id = uid
          resource.cookie_jar = YAML.dump(cookie_jar)
          resource.email = authentication_hash[:email]
          resource.save if resource.changed?
        end

        return fail(:invalid) unless resource and resource.id

        if validate(resource) { not resource.nil? }
          success!(resource)
        end
      end

      def validate_username_and_password(username, password)
        agent = Mechanize.new
        
        # try to open OpenTable's login page
        begin
          login_page = agent.get("https://secure.opentable.com/login.aspx")
        rescue Exception => e
          return nil
        end
        
        login_form = login_page.form('Login')
        login_form.txtUserEmail = username
        login_form.txtUserPassword = password
        login_form.checkbox_with(:name => 'chkRemember').check
        
        # try to submit the filled in login form
        begin
          new_page = agent.submit(login_form, login_form.buttons.first)
        rescue Exception => e
          return nil
        end
        
        # if email and password are valid on OpenTable, return the associated cookie jar
        # otherwise register the user automatically
        if not new_page.body =~ /txtUserPassword/
          return agent.cookie_jar
        end
        nil
      end

      private

      def decorate(resource)
        super
      end
    end
  end
end

module Devise
  module Models
    module OpenTableAuthenticatable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
      end
    end

    module Validatable

      def self.included(base)
        base.extend ClassMethods
        assert_validations_api!(base)

        base.class_eval do
          validates_presence_of   :email, :if => :email_required?
          validates_uniqueness_of :email, :case_sensitive => (case_insensitive_keys != false), :allow_blank => false, :if => :email_changed?
          validates_format_of     :email, :with => email_regexp, :allow_blank => false, :if => :email_changed?

          validates_presence_of     :password, :if => :password_required?
          validates_confirmation_of :password, :if => :password_required?
          validates_length_of       :password, :within => password_length, :allow_blank => true
        end
      end
    end
  end
end

Warden::Strategies.add(:open_table_authenticatable, Devise::Strategies::OpenTableAuthenticatable)
Devise.add_module(:open_table_authenticatable,
                  :strategy => true,
                  :model => "app/models/user.rb")

class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :open_table_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :phone, :email, :ot_id, :remember_me
  has_many :requests, dependent: :destroy

  before_save { |user| user.email = email.downcase }

  validates :name, presence: true
  validates :phone, format: { with: /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/ }

  def password_required?
    return false
  end

  def mechanize
    m = Mechanize.new
    m.cookie_jar = YAML.load(self.cookie_jar)
    return m
  end
end