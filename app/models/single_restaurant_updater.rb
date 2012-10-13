# SingleRestaurantUpdater
#
# This job takes the given restaurant_link on OpenTable and then
# saves the restaurant found on it to the Rails database. It also
# saves every OpenTable restaurant ID to Redis and adds the
# restaurant link to Redis if there were errors while trying to
# save it. Finally it queues RestaurantUpdater with process_last-
# -_restaurant set to true if it's working on the last restaurant
# to be processed.
#
class SingleRestaurantUpdater
  @queue = :restaurants
  @@agent = Mechanize.new
  @@redis = Redis.new
  def self.perform(restaurant_link)
    begin
      restaurant_page = @@agent.get("http://www.opentable.com/#{restaurant_link}")
      Rails.logger.info "Currently saving #{restaurant_page.title[3..(restaurant_page.title.length-15)]}"
    rescue Exception => e
      Rails.logger.info "There was an error loading the page http://www.opentable.com/#{restaurant_link}."
      raise e
      return
    end
    opentable_restaurant_id = CGI.parse(URI.parse(restaurant_page.search("form").first.attr("action")).query)["rid"].join("")
    @@redis.sadd "opentable_restaurant_ids", opentable_restaurant_id
    restaurant = Restaurant.where("opentable_restaurant_id = ?", opentable_restaurant_id).first || Restaurant.new
    restaurant_name = restaurant_page.search("[itemprop='name']").text
    location_block = restaurant_page.search("span#ProfileOverview_lblAddressText").inner_html
    if (location_block.index("<") != location_block.rindex("<"))
      location = location_block[/\A(.*?)\</][0...-1]
      location_block.slice! (location + "<br>")
      location += (" " + location_block[/\A(.*?)\</][0...-1])
    else
      location = location_block[/\A(.*?)\</][0...-1]
      location_block.slice! location_block[/\A(.*?)\</][0...-1]
    end
    restaurant_address = location
    restaurant_city = location_block[/\>(.*?)\,/][1...-1]
    restaurant_state = location_block[/\,(.*?)\z/][2...4]
    restaurant_ZIP = location_block[/\,(.*?)\z/][6...11]
    if restaurant.opentable_restaurant_id != opentable_restaurant_id or restaurant.name != restaurant_name or restaurant.address != restaurant_address or restaurant.city != restaurant_city or restaurant.state != restaurant_state or restaurant["ZIP"] != restaurant_ZIP
      restaurant.opentable_restaurant_id = opentable_restaurant_id
      restaurant.name = restaurant_name
      restaurant.address = restaurant_address
      restaurant.city = restaurant_city
      restaurant.state = restaurant_state
      restaurant["ZIP"] = restaurant_ZIP
      restaurant.save
      if restaurant.errors.any?
        @@redis.sadd "retry_restaurant_pages", restaurant_link
        error_message = "There were #{restaurant.errors.count.to_s + (restaurant.errors.count == 1 ? " error" : " errors")} while trying to save this restaurant.\n"
        restaurant.errors.full_messages.each { |msg| error_message += "#{msg}\n" }
        Rails.logger.info error_message
      end
    end
  end
end