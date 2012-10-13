class SignupController < ApplicationController
  def create
    agent = Mechanize.new
    if params[:password] != params[:repeat_password]
      error_with_opentable("Password did not match repeated password.")
      return
    end
    
    # check to see if user already has an account on Opentable
    begin
      Rails.logger.info "Trying to open the login page on OpenTable:"
      login_page = agent.get("https://secure.opentable.com/login.aspx")
    rescue Exception => e
      error_with_opentable("There was an error trying to open the login page on OpenTable.  Please try again later.")
      return
    end
    
    login_form = login_page.form('Login')
    login_form.txtUserEmail = params[:email][0]
    login_form.txtUserPassword = params[:password]
    login_form.checkbox_with(:name => 'chkRemember').check
    
    # try to submit the filled in login form
    begin
      Rails.logger.info "Trying to submit the filled in login form on OpenTable:"
      new_page = agent.submit(login_form, login_form.buttons.first)
    rescue Exception => e
      error_with_opentable("There was an error trying to submit the filled in login page on OpenTable.  Please try again later.")
      return
    end
    
    # if email and password are valid on OpenTable
    if not new_page.body =~ /txtUserPassword/
      
      # if the account was already created during an attempted registration but the phone number was invalid
      begin
        Rails.logger.info "User's account has already been created: try to update with the newly listed phone number."
        Rails.logger.info "Going to My Profile on OpenTable: http://www.opentable.com/myprofile.aspx"
        profile_page = agent.get("http://www.opentable.com/myprofile.aspx")
      rescue Exception => e
        error_with_opentable("Your account has already been created but there was an error going to My Profile on OpenTable to save your new valid phone number. Please try again later.")
        return
      end
      
      begin
        Rails.logger.info "Going to Account Details on OpenTable: "
        profile_form = profile_page.form('Form1')
        account_details_page = agent.submit(profile_form, profile_form.buttons[2])
      rescue Exception => e
        error_with_opentable("Your account has already been created but there was an error going to Account Details on OpenTable to save your new valid phone number. Please try again later.")
        return
      end
      
      begin
        Rails.logger.info "Updating the phone number on My Profile on OpenTable:"
        account_details_form = account_details_page.form('Form2')
        account_details_form.field_with(:name => "PhoneEntry_Phone$txtPhone1").value = params[:phone][0]
        update_profile_page = agent.submit(account_details_form, account_details_form.buttons.last)
        update_profile_page.uri.absolute
        if update_profile_page.uri.to_s == "https://secure.opentable.com/editprofile.aspx"
          Rails.logger.info "There were error(s): "
          errors = ""
          update_profile_page.parser.css("div#valSummary ul li").each do |error|
            errors += (error.text + " ")
          end
          error_with_opentable(errors)
          return
        end
      rescue Exception => e
        error_with_opentable("Your account has already been created but there was an error updating the phone number on My Profile on OpenTable to save your new valid phone number. Please try again later.")
        return
      end
      
      success_with_opentable("You've successfully registered for OpenTable!  Please feel free to sign in now.")
      return
    end
    
    # the given email and password were not a valid signin on OpenTable, so we must create a new account
    begin
      Rails.logger.info "Currently opening OpenTable's registration page."
      register_page = agent.get("https://secure.opentable.com/register.aspx")
    rescue Exception => e
      error_with_opentable("There was an error accessing OpenTable's registration page to register your information. Please try again later.")
      return
    end
    
    register_form = register_page.form('Form1')
    register_form.field_with(:name => "ucName$txtFirstName").value = params[:first_name]
    register_form.field_with(:name => "ucName$txtLastName").value = params[:last_name]
    register_form.field_with(:name => "txtEmail").value = params[:email][0]
    register_form.field_with(:name => "txtReEnterEmail").value = params[:email][0]
    register_form.field_with(:name => "txtPassword").value = params[:password]
    register_form.field_with(:name => "txtReEnterPassword").value = params[:password]
    register_form.field_with(:name => "cboCity").options[1].select
    register_form.checkbox_with(:name => "chkOffers").uncheck
    
    begin
      Rails.logger.info "Currently submitting OpenTable's registration form."
      done_page = agent.submit(register_form, register_form.buttons.first)
    rescue Exception => e
      error_with_opentable("There was an error submitting OpenTable's registration form to register your information. Please try again later.")
      return
    end
    
    if done_page.parser.css("div#ValSummary ul").size > 0
      Rails.logger.info "There were error(s): "
      errors = ""
      done_page.parser.css("div#ValSummary ul li").each do |error|
        errors += (error.text + ". ")
      end
      error_with_opentable(errors)
      return
    end
    
    begin
      Rails.logger.info "Going to My Profile on OpenTable: http://www.opentable.com/myprofile.aspx"
      profile_page = agent.page.link_with(:text => 'My Profile').click
    rescue Exception => e
      error_with_opentable("There was an error accessing My Profile on OpenTable to register your information. Please try again later.")
      return
    end
    
    begin
      Rails.logger.info "Going to Account Details on OpenTable: "
      profile_form = profile_page.form('Form1')
      account_details_page = agent.submit(profile_form, profile_form.buttons[2])
    rescue Exception => e
      error_with_opentable("There was an error accessing Account Details on OpenTable to register your information. Please try again later.")
      return
    end
    
    begin
      Rails.logger.info "Updating the phone number on My Profile on OpenTable:"
      account_details_form = account_details_page.form('Form2')
      account_details_form.field_with(:name => "PhoneEntry_Phone$txtPhone1").value = params[:phone][0]
      update_profile_page = agent.submit(account_details_form, account_details_form.buttons.last)
      update_profile_page.uri.absolute
      if update_profile_page.uri.to_s == "https://secure.opentable.com/editprofile.aspx"
        Rails.logger.info "There were error(s): "
        errors = ""
        update_profile_page.parser.css("div#valSummary ul li").each do |error|
          errors += (error.text + " ")
        end
        error_with_opentable(errors)
        return
      end
    rescue Exception => e
      error_with_opentable("There was an error updating the phone number on My Profile on OpenTable to register your information. Please try again later.")
      return
    end
    
    success_with_opentable("You've successfully registered for OpenTable!  Please feel free to sign in now.")
  end
  
  private
    def error_with_opentable(error)
      Rails.logger.info error
      flash[:alert] = error
      respond_to do |format|
        format.html { redirect_to root_path }
      end
    end
    
    def success_with_opentable(message)
      Rails.logger.info message
      flash[:success] = message
      respond_to do |format|
        format.html { redirect_to root_path }
      end
    end
end
