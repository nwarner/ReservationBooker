class AddOpenTableParametersToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :opentable_parameters, :string
  end
end
