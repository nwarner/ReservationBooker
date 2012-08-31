class CreateRestaurants < ActiveRecord::Migration
  def change
    create_table :restaurants do |t|
      t.string :rest_id
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :ZIP

      t.timestamps
    end
  end
end
