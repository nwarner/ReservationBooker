class UpdateRestaurants
  @queue = :update
  
  def self.perform
    puts "Doing long running task here!!"
    sleep 5
  end
end