class AddAvailableTimesToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :available_times, :string
  end
end
