class AddRestaurantIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :restaurant_id, :integer
    rename_column :restaurants, :rest_id, :opentable_restaurant_id
  end
end
