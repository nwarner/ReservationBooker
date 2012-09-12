task :update_restaurants do
  RestaurantUpdater.perform(true)
end