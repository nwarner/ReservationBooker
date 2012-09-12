# RestaurantUpdater
#
# This job queues RestaurantListingUpdater for every location link
# on OpenTable if update_restaurant_listings is set to true.
# Otherwise it queues SingleRestaurantUpdater for every restaurant
# link found on the saved array of restaurant listings saved to
# Redis. If processing_last_restaurant is set to true it requeues
# SingleRestaurantUpdater for any restaurants that failed to save
# and deletes all restaurants that are no longer listed with Open-
# -Table, finally reindexing their information for the Soulmate
# Autocomplete widgets. It then displays the total time this took.
#
# Updating from scratch takes 59.6 minutes with 15 errors.
# Updating with previously gotten restaurant listings and no saved restaurants takes 
#
class RestaurantUpdater
  @queue = :restaurant_updater
  @@agent = Mechanize.new
  @@initial_time = Time.now
  @@redis = Redis.new
  STATES = %w(AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO
              MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY)
  def self.perform(update_restaurant_listings=false, processing_last_restaurant=false)
    if processing_last_restaurant
      Restaurant.all.each { |restaurant| restaurant.delete if !(@@redis.sismember "opentable_restaurant_ids", restaurant.opentable_restaurant_id) }
      Restaurant.reindex
      Rails.logger.info "Updating all restaurants took #{(Time.now - @@initial_time) / 60.0} minutes."
    else
      if update_restaurant_listings or @@redis.scard("restaurant_listings").zero?
        Rails.logger.info "RestaurantUpdater: beginning to update restaurant listings and restaurants."
        @@redis.del "restaurant_listings"
        @@redis.del "opentable_restaurant_ids"
        @@redis.del "retry_restaurant_pages"
        STATES.each do |state|
          begin
            Rails.logger.info "Currently loading the page http://www.opentable.com/city.aspx?s=#{state}."
            state_page = @@agent.get("http://www.opentable.com/city.aspx?s=#{state}")
          rescue Exception => e
            Rails.logger.info "There was an error loading the page http://www.opentable.com/city.aspx?s=#{state}."
            raise e
            return
          end
          state_page.links[7..state_page.links.length-29].each { |location_link| Resque.enqueue RestaurantListingUpdater, "http://www.opentable.com/#{location_link.uri.to_s}" }
        end
      else
        Rails.logger.info "RestaurantUpdater: beginning to update restaurants using saved restaurant listings."
        @@redis.del "retry_restaurant_pages"
        @@redis.smembers("restaurant_listings").each do |restaurant_listing|
          begin
            Rails.logger.info "Currently saving #{restaurant_listing}."
            location_page = @@agent.get(restaurant_listing)
          rescue Exception => e
            Rails.logger.info "There was an error loading the page #{restaurant_listing}."
            raise e
            return
          end
          location_page.search("a.r").each { |link| Resque.enqueue SingleRestaurantUpdater, link.attr("href").to_s }
        end
      end
    end
  end
end