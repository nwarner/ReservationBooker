class RemoveRestaurantListings < ActiveRecord::Migration
  def up
    drop_table "restaurant_listings"
  end

  def down
  end
end
