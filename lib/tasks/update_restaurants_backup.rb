class RestaurantUpdater
  
  @queue = :restaurant_update
  
  # states = %w(AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO
  #             MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY)
  #            
  # Use this code to update the array of restaurant listings:
  #
  # agent = Mechanize.new
  # page = agent.get('http://www.opentable.com')
  #
  # states.each do |state|
  #   state_page = agent.get("http://www.opentable.com/city.aspx?s=#{state}")
  #   state_len = state_page.links.length
  #   puts "Currently examining state #{state}" 
  #   state_page.links[7..state_len-29].each do |city_link|
  #     city_page = agent.get("http://www.opentable.com/#{city_link.uri}")
  #     puts "Currently examining #{city_link.text}"
  #     city_page.links.each do |link|
  #       if link.text.include? 'See all'
  #         city_page = link.click
  #         break
  #       end
  #     end
  #     restaurant_listings.push(city_page.uri)
  #   end
  # end
  #
  # restaurant_listings = restaurant_listings.uniq
  # puts restaurant_listings
  
  RESTAURANT_LISTINGS = %w(http://www.opentable.com/alabama-restaurant-listings
    http://www.opentable.com/anchorage-alaska-restaurant-listings
    http://www.opentable.com/phoenix-restaurant-listings
    http://www.opentable.com/arkansas-restaurant-listings
    http://www.opentable.com/los-angeles-restaurant-listings
    http://www.opentable.com/san-francisco-bay-area-restaurant-listings
    http://www.opentable.com/san-diego-california-restaurant-listings
    http://www.opentable.com/central-coast-restaurant-listings
    http://www.opentable.com/sacramento-california-restaurant-listings
    http://www.opentable.com/palm-springs-restaurant-listings
    http://www.opentable.com/lake-tahoe-restaurant-listings
    http://www.opentable.com/denver-colorado-restaurant-listings
    http://www.opentable.com/new-york-restaurant-listings
    http://www.opentable.com/philadelphia-pennsylvania-restaurant-listings
    http://www.opentable.com/baltimore-maryland-restaurant-listings
    http://www.opentable.com/orlando-florida-restaurant-listings
    http://www.opentable.com/jacksonville-florida-restaurant-listings
    http://www.opentable.com/tampa-florida-restaurant-listings
    http://www.opentable.com/miami-restaurant-listings
    http://www.opentable.com/naples-florida-restaurant-listings
    http://www.opentable.com/nw-florida-restaurant-listings
    http://www.opentable.com/key-west-restaurant-listings
    http://www.opentable.com/atlanta-georgia-restaurant-listings
    http://www.opentable.com/hawaii-restaurant-listings
    http://www.opentable.com/idaho-restaurant-listings
    http://www.opentable.com/jackson-hole-wyoming-restaurant-listings
    http://www.opentable.com/chicago-illinois-restaurant-listings
    http://www.opentable.com/st-louis-missouri-restaurant-listings
    http://www.opentable.com/iowa-restaurant-listings
    http://www.opentable.com/indiana-restaurant-listings
    http://www.opentable.com/cincinnati-dayton-restaurant-listings
    http://www.opentable.com/kentucky-restaurant-listings
    http://www.opentable.com/sw-indiana-restaurant-listings
    http://www.opentable.com/kansas-city-kansas-restaurant-listings
    http://www.opentable.com/new-orleans-louisiana-restaurant-listings
    http://www.opentable.com/new-england-restaurant-listings
    http://www.opentable.com/portland-oregon-restaurant-listings
    http://www.opentable.com/washington-dc-restaurant-listings
    http://www.opentable.com/rest_list.aspx?m=370
    http://www.opentable.com/michigan-restaurant-listings
    http://www.opentable.com/rest_list.aspx?m=367
    http://www.opentable.com/minneapolis-minnesota-restaurant-listings
    http://www.opentable.com/mississippi-restaurant-listings
    http://www.opentable.com/lake-of-the-ozarks-missouri-restaurant-listings
    http://www.opentable.com/springfield-missouri-restaurant-listings
    http://www.opentable.com/montana-restaurant-listings
    http://www.opentable.com/nebraska-restaurant-listings
    http://www.opentable.com/las-vegas-restaurant-listings
    http://www.opentable.com/atlantic-city-new-jersey-restaurant-listings
    http://www.opentable.com/new-mexico-restaurant-listings
    http://www.opentable.com/raleigh-durham-chapel-hill-restaurant-listings
    http://www.opentable.com/greensboro-winston-salem-highpoint-restaurant-listings
    http://www.opentable.com/western-north-carolina-restaurant-listings
    http://www.opentable.com/coastal-north-carolina-restaurant-listings
    http://www.opentable.com/charlotte-north-carolina-restaurant-listings
    http://www.opentable.com/pinehurst-north-carolina-restaurant-listings
    http://www.opentable.com/north-dakota-restaurant-listings
    http://www.opentable.com/cleveland-ohio-restaurant-listings
    http://www.opentable.com/columbus-ohio-restaurant-listings
    http://www.opentable.com/toledo-ohio-restaurant-listings
    http://www.opentable.com/oklahoma-restaurant-listings
    http://www.opentable.com/pittsburgh-pennsylvania-restaurant-listings
    http://www.opentable.com/rest_list.aspx?m=379
    http://www.opentable.com/south-carolina-restaurant-listings
    http://www.opentable.com/south-dakota-restaurant-listings
    http://www.opentable.com/memphis-tennessee-restaurant-listings
    http://www.opentable.com/nashville-tennessee-restaurant-listings
    http://www.opentable.com/east-tennessee-restaurant-listings
    http://www.opentable.com/dallas-texas-restaurant-listings
    http://www.opentable.com/el-paso-southwest-texas-restaurant-listings
    http://www.opentable.com/texas-panhandle-restaurant-listings
    http://www.opentable.com/austin-texas-restaurant-listings
    http://www.opentable.com/houston-texas-restaurant-listings
    http://www.opentable.com/san-antonio-texas-restaurant-listings
    http://www.opentable.com/corpus-christi-texas-restaurant-listings
    http://www.opentable.com/utah-restaurant-listings
    http://www.opentable.com/virginia-restaurant-listings
    http://www.opentable.com/seattle-washington-restaurant-listings
    http://www.opentable.com/west-virginia-restaurant-listings
    http://www.opentable.com/wisconsin-restaurant-listings)
  
  def self.perform(update_restaurant_same_task=false, job_identifier=nil)
    
    job_identifier ||= SecureRandom.uuid
    
    # clean up dead workers, if any
    Resque.workers.first.prune_dead_workers if Resque.workers.first
    working = Resque.working.detect { |v| v.job["payload"]["class"] == "SingleRestaurantUpdater" }
    
    if working or update_restaurant_same_task
      job_identifier_check = Resque.redis.get("restaurant_working")
      if not update_restaurant_same_task and job_identifier_check != job_identifier
        return false
      elsif update_restaurant_same_task and job_identifier_check != job_identifier
        restaurant_pid = Resque.redis.get("restaurant_working_pid")
        begin
          pid = Process.getpgid(restaurant_pid.to_i)
          return false if pid != Process.pid
        rescue Errno::ESRCH => e
          restaurant_pid = Process.pid
          Resque.redis.set("restaurant_working_pid", restaurant_pid)
        end
      else
        Resque.redis.set("restaurant_working", job_identifier)
      end
    end
    
    # insert locking code here
  
    agent = Mechanize.new
    time = Time.now
      
    if Resque.redis.get("restaurant_working_done") != job_identifier
      
      # for each geographical region in restaurant_listings
      RESTAURANT_LISTINGS.each do |restaurant_listing|
        
        location_page = agent.get(restaurant_listing)  # load the restaurant listings page for that region
        
        # for each restaurant link in that region
        location_page.search("a.r").each do |link|
          
          if update_restaurant_same_task
            SingleRestaurantUpdater.perform(link.attr("href").to_s, job_identifier)
          else
            Resque.enqueue SingleRestaurantUpdater, link.attr("href").to_s, job_identifier
          end
          
        end
      end
    end
    
    Resque.redis.set("restaurant_working_done", job_identifier)
    
    # if no restaurants enqueued call this
    if Resque.size(:single_restaurant).zero?
      Restaurant.where("updated_at < ?", time.utc).destroy_all
      Restaurant.reindex      
      Resque.redis.del("restaurant_working_done")
      Resque.redis.del("restaurant_working")
      Resque.redis.del("restaurant_working_pid")
    end
  end
end

class SingleRestaurantUpdater
  @queue = :single_restaurant
  @@m = Mechanize.new
  
  def self.perform(restaurant_link, job_identifier)
    # puts "Currently saving #{restaurant_link}"
    Rails.logger.info "Currently saving #{restaurant_link}"
    
    restaurant_page = @@m.get("http://www.opentable.com/#{restaurant_link}")
    restaurant_page_attr = CGI.parse URI.parse(restaurant_page.search("form").first.attr("action")).query
      
    restaurant = Restaurant.where("opentable_restaurant_id = ?", restaurant_page_attr["rid"].join("").to_i).first
    restaurant ||= Restaurant.new
      
    restaurant.opentable_restaurant_id = restaurant_page_attr["rid"].join("").to_i
      
    address_block = restaurant_page.search("span#ProfileOverview_lblAddressText").inner_html
        
    # if we have more than two <br>'s in the address block
    if (address_block.index("<") != address_block.rindex("<"))
      address = address_block[/\A(.*?)\</][0...-1]
      address_block.slice! (address + "<br>")
      address += (" " + address_block[/\A(.*?)\</][0...-1])
    # if we just have one <br>
    else
      address = address_block[/\A(.*?)\</][0...-1]
      address_block.slice! address_block[/\A(.*?)\</][0...-1]
    end
      
    restaurant.name = restaurant_page.search("[itemprop='name']").text
    restaurant.address = address
    restaurant.city = address_block[/\>(.*?)\,/][1...-1]
    restaurant.state = address_block[/\,(.*?)\z/][2...4]
    restaurant["ZIP"] = address_block[/\,(.*?)\z/][6...11]
    restaurant.updated_at = Time.now
    restaurant.save
    
    # if last restaurant to be loaded, call the Restaurant thing again
    if Resque.size(:single_restaurant) == 0
      Resque.enqueue(RestaurantUpdater, false, job_identifier) 
    end
  end
end