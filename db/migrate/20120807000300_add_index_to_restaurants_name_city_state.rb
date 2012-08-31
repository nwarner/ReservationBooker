class AddIndexToRestaurantsNameCityState < ActiveRecord::Migration
  def change
    add_index :restaurants, :name
    add_index :restaurants, :city
    add_index :restaurants, :state
  end
end
