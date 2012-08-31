class AddOpentableIdAndCookieJarToUsers < ActiveRecord::Migration
  def change
    add_column :users, :opentable_id, :string
    add_column :users, :cookie_jar, :text
  end
end
