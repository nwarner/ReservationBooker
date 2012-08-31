class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :rest_id
      t.integer :user_id

      t.timestamps
    end
    add_index :requests, [:user_id, :created_at]
  end
end
