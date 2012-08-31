class ChangeDefaultReservedRequests < ActiveRecord::Migration
  def up
    change_column :requests, :isReserved, :boolean, default: false
  end

  def down
  end
end
