class AddRemoveToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :remove, :boolean, default: false
  end
end
