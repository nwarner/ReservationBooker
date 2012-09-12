class RemoveRemoveFromRestaurants < ActiveRecord::Migration
  def up
    remove_column :restaurants, :remove
  end

  def down
  end
end
