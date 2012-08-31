class AddInformationToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :party_size, :integer
    add_column :requests, :time, :datetime
  end
end
