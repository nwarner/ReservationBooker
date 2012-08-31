class AddEncryptedPasswordtoUsers < ActiveRecord::Migration
  def up
  	add_column :users, :encrypted_password, :string
  end

  def down
  end
end
