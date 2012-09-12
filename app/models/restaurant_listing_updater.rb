# RestaurantListingUpdater
#
# This job takes the given restaurant_listing_link and then queues
# SingleRestaurantUpdater for every restaurant link found for this
# location on OpenTable.
#
class RestaurantListingUpdater
  @queue = :restaurant_listing_updater
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
    link_save = ""
    city_page.links.each do |link|
      if link.text.include? 'See all'
        link_save = link.href.to_s
        break
      end
    end
    if @@redis.sadd "restaurant_listings", link_save
      begin
        Rails.logger.info "Currently saving #{link_save}."
        location_page = @@agent.get(link_save)
      rescue Exception => e
        Rails.logger.info "There was an error loading the page #{link_save}."
        raise e
        return
      end
      location_page.search("a.r").each { |link| Resque.enqueue SingleRestaurantUpdater, link.attr("href").to_s }
    end
  end
end