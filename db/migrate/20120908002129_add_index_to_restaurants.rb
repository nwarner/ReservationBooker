class AddIndexToRestaurants < ActiveRecord::Migration
  def change
    add_index :restaurants, :opentable_restaurant_id
  end
end
