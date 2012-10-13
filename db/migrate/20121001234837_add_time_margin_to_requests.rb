class AddTimeMarginToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :time_margin, :integer
  end
end
