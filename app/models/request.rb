class Request < ActiveRecord::Base
  before_save :update_available_times
  
  attr_accessible :user_id, :party_size, :time, :isReserved, :restaurant_id, :available_times, :opentable_parameters
  
  serialize :available_times
  serialize :opentable_parameters

  belongs_to :user
  belongs_to :restaurant

  validates :user_id, presence: true
  validates :party_size, presence: true
  validates :time, :presence => true
  validates :restaurant, presence: true

  default_scope order: 'requests.created_at DESC'

  # try to reserve this request on OpenTable
  def try_reserve
    
    # if the desired time is available to reserve
    if self.available_times.include? (self.time.strftime("%-m/%e/%Y ") + self.time.strftime("%l").strip + self.time.strftime(":%M:%S %p %z"))
      agent = User.find(self.user_id).mechanize  # get the user's mechanize agent with the appropriate cookie-jar
      
      # get the reservation page for the desired time
      reservation_uri = "http://www.opentable.com/details.aspx?"
      reservation_uri += "shpu=#{self.opentable_parameters[:shpu]}&"
      reservation_uri += "hpu=#{self.opentable_parameters[:hpu]}&"
      reservation_uri += "rid=#{self.opentable_parameters[:rid]}&"
      reservation_uri += "d=#{self.opentable_parameters[:d]}&"
      reservation_uri += "p=#{self.opentable_parameters[:p]}&"
      reservation_uri += "pt=#{self.opentable_parameters[:pt]}&"
      reservation_uri += "i=#{self.opentable_parameters[:i]}&"
      reservation_uri += "ss=#{self.opentable_parameters[:ss]}&"
      reservation_uri += "sd=#{self.opentable_parameters[:sd]}"
      reservation_page = agent.get(reservation_uri)

      # if the reservation isn't still available for some reason
      if reservation_page.parser.css("span#lblMsgSubTitle").text == "Your Request Cannot Be Completed"
        self.isReserved = false  # the request wasn't reserved
        reservation_status = "Request was not reserved because that reservation time is no longer available."
      else

        # confirm the reservation
        reservation_form = reservation_page.form('SearchForm')
        submit_button = reservation_form.button_with(:name => 'btnContinueReservation')
        done_page = agent.submit(reservation_form, submit_button)

        # check if request was completed
        if done_page.parser.css("span#lblMsgSubTitle").text == "Your Request Cannot Be Completed"
          self.isReserved = false  # the request was not reserved
          reservation_status =
            "Request was not reserved because you have already confirmed a reservation within two and half hours of the current time."
        else
          self.isReserved = true  # the request was successfully completed & reserved
          reservation_status = "Request was successfully reserved."
        end
      end
    else
      self.isReserved = false  # the desired time was not available to reserve
      reservation_status = "Request was not reserved because there were no open reservations that matched your desired time."
    end
    self.save  # save the request and update the list of available times
    return reservation_status  # return the reservation status
  end
  
  # update the available reservation times close to the desired time
  def update_available_times
    agent = User.find(self.user_id).mechanize  # get the user's mechanize agent with the appropriate cookie-jar
    
    # get the restaurant page with reservation times
    restaurant_address = "http://www.opentable.com/opentables.aspx"
    restaurant_address += "?p=#{self.party_size}"
    restaurant_address += "&d=#{self.time.strftime("%-m/%e/%Y") + "%20" + self.time.strftime("%I:%M:%S") + "%20" + self.time.strftime("%p")}"
    restaurant_address += "&rid=#{self.restaurant.opentable_restaurant_id}&t=single"
    restaurant_page = agent.get(restaurant_address)

    # get the reservation confirmation page
    times = restaurant_page.search("ul[@class='ResultTimes']/li[a]")
    matching_time, self.available_times, self.opentable_parameters = "", [], {}

    # if times are listed close to the desired time
    if times.size != 0
      
      # go through the available reservation times
      times.each do |current_time|
        self.available_times.push(current_time.attributes['a'].to_s.gsub(/[\[\]\']/,'').split(',')[0] + self.time.strftime(" %z"))
        matching_time = current_time if self.available_times.last == self.time.strftime("%-m/%e/%Y ") +
                                                                     self.time.strftime("%l").strip +
                                                                     self.time.strftime(":%M:%S %p")
      end
      
      # if the selected reservation time was available save it to available times
      if matching_time != ""
        self.available_times = [self.time.strftime("%-m/%e/%Y ") + self.time.strftime("%l").strip + self.time.strftime(":%M:%S %p")]
      else
        matching_time = times.first  # otherwise generate the OpenTable parameters from the first listed reservation time
      end
      
      # get the OpenTable parameters
      matching_time_attributes = matching_time.attributes['a'].to_s.gsub(/[\[\]\']/,'').split(',')
      uri_attributes = CGI::parse(restaurant_page.uri.to_s)
      hpu = times.first.parent.attributes['hpu'].to_s
      d = CGI::escape(matching_time_attributes[0]).gsub("+", "%20")
      rid = self.restaurant.opentable_restaurant_id
      p = uri_attributes["http://www.opentable.com/opentables.aspx?p"].join('')
      pt = matching_time_attributes[1]
      i = matching_time_attributes[2]
      sd = CGI::escape(uri_attributes['d'].join(''))
        
      # save the OpenTable parameters
      self.opentable_parameters = { :shpu => "1", :hpu => hpu, :rid => rid, :d => d, :p => p, :pt => pt, :i => i, :ss => "1", :sd => sd }
    end
  end

  # cancel this request on OpenTable
  def cancel_reservation
    
    # get the profile page for the user
    agent = User.find(user_id).mechanize
    profile_page = agent.get("http://www.opentable.com/myprofile.aspx")

    # if one or more reservations are listed
    if profile_page.parser.css("div.RestaurantName a").size > 0
      
      # find the reservation we want to cancel in the list
      index = -1
      for i in 0..(profile_page.parser.css("div.RestaurantName a").size-1) do
        index = i if profile_page.parser.css("div.RestaurantName a")[i].text == self.restaurant.name
      end
      
      # if the reservation is there, cancel the reservation
      if index >= 0
        cancel_page = agent.get(profile_page.parser.css("div.C a")[index]['href'])
        cancel_form = cancel_page.form('Form1')
        submit_button = cancel_form.button_with(:name => 'btnCancelReso')
        done_page = agent.submit(cancel_form, submit_button)
        
        self.isReserved = false
        self.save  # save the request
        reservation_status = "Reservation was successfully canceled."
      end
    else
      reservation_status = "Reservation was not canceled."
    end
    return reservation_status  # return the reservation status
  end
end