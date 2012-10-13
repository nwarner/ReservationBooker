# RestaurantListingUpdater
#
# This job takes the given restaurant_listing_link and then queues
# SingleRestaurantUpdater for every restaurant link found for this
# location on OpenTable.
#
class RestaurantListingUpdater
  @queue = :restaurants
  @@agent = Mechanize.new
  @@redis = Redis.new
  def self.perform(restaurant_listing_link)
    begin
      Rails.logger.info "Currently loading the page #{restaurant_listing_link}."
      city_page = @@agent.get(restaurant_listing_link)
    rescue Exception => e
      Rails.logger.info "There was an error loading the page #{restaurant_listing_link}."
      raise e
      return
    end
    link_save = city_page.links[city_page.links.find_index { |link| link.text.include? 'See all' }].href.to_s
    if @@redis.sadd "restaurant_listings", link_save
      begin
        Rails.logger.info "Currently saving #{link_save}."
        location_page = @@agent.get(link_save)
      rescue Exception => e
        Rails.logger.info "There was an error loading the page #{link_save}."
        raise e
        return
      end
      location_page.search("a.r").each { |link| @@redis.sadd "restaurants", link.attr("href").to_s }
    end
  end
end