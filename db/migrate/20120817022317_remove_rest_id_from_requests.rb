class RemoveRestIdFromRequests < ActiveRecord::Migration
  def change
  	remove_column :requests, :rest_id
  end
end
