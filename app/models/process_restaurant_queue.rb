class ProcessRestaurantQueue
  @queue = :restaurant_updater
  @@redis = Redis.new
  def self.perform
    while @@redis.get("restaurant_done_processing").to_i.zero?
      unless @@redis.scard("restaurant_location_links").zero?
        Resque.enqueue RestaurantListingUpdater, @@redis.spop("restaurant_location_links")
      end
      unless @@redis.scard("restaurants").zero?
        Resque.enqueue SingleRestaurantUpdater, @@redis.spop("restaurants")
      end
    end
  end
end