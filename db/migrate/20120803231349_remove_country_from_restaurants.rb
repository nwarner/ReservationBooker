class RemoveCountryFromRestaurants < ActiveRecord::Migration
  def up
    remove_column :restaurants, :country
  end

  def down
    add_column :restaurants, :country, :string
  end
end
