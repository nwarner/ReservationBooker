class AddReservedToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :isReserved, :boolean
  end
end
