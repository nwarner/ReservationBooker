class Request < ActiveRecord::Base
  TIME_MARGINS = [ { :value => 30, :name => "30 minutes" }, 
                   { :value => 45, :name => "60 minutes" } ]
  
  before_save :update_available_times
  
  attr_accessible :user_id, :party_size, :time, :time_margin, :isReserved, :restaurant_id, :available_times, :opentable_parameters
 
  serialize :available_times
  serialize :opentable_parameters

  belongs_to :user
  belongs_to :restaurant

  validates :user_id, presence: true
  validates :party_size, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :time, :presence => true
  validates :restaurant, presence: true

  default_scope order: "requests.created_at DESC"
  
  def self.time_margins_short
    [["exact time", 0], ["\u00B115 mins", 15],["\u00B130 mins", 30],["\u00B145 mins", 45],
    ["\u00B11 hr", 60],["\u00B11.5 hrs", 90],["\u00B12 hrs", 120],["\u00B13 hrs", 180],["\u00B14 hrs", 240]]
  end
  
  def self.time_margins_long
    [["\u00B10 minutes (no margin)", 0], ["\u00B115 minutes", 15],["\u00B130 minutes", 30],["\u00B145 minutes", 45],
    ["\u00B11 hour", 60],["\u00B11.5 hours", 90],["\u00B12 hours", 120],["\u00B13 hours", 180],["\u00B14 hrs", 240]]
  end
  
  # try to reserve this request on OpenTable
  def try_reserve
    
    # if the desired time is available to reserve
    if self.available_times.include? (self.time.strftime("%-m/%-d/%Y ") + self.time.strftime("%l").strip + self.time.strftime(":%M:%S %p %z"))
      agent = User.find(self.user_id).mechanize  # get the user's mechanize agent with the appropriate cookie-jar
      
      # if no opentable_parameters were saved, try again
      self.update_available_times if self.opentable_parameters[:shpu] == -1
      
      # try to get the reservation page for the desired time
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
      begin
        reservation_page = agent.get(reservation_uri)
      rescue Exception => e
        self.isReserved = false
        reservation_status = "Request was not reserved because there was a problem connecting with OpenTable servers.  Please try again."
      end

      # if the reservation isn't still available for some reason
      if reservation_page.parser.css("span#lblMsgSubTitle").text == "Your Request Cannot Be Completed"
        self.isReserved = false  # the request wasn't reserved
        reservation_status = "Request was not reserved because that reservation time is no longer available."
      else

        # try to confirm the reservation
        reservation_form = reservation_page.form('SearchForm')
        submit_button = reservation_form.button_with(:name => 'btnContinueReservation')
        begin
          done_page = agent.submit(reservation_form, submit_button)
        rescue Exception => e
          self.isReserved = false
          reservation_status = "Request was not reserved because there was a problem connecting with OpenTable servers.  Please try again."
        end

        # check if request was completed
        if done_page.parser.css("span#lblMsgSubTitle").text == "Your Request Cannot Be Completed"
          self.isReserved = false  # the request was not reserved
          reservation_status = done_page.parser.css("span#lblErrorMsg").text
        else
          self.isReserved = true  # the request was successfully completed & reserved
          reservation_status = "Request was successfully reserved."
        end
      end
    else
      self.isReserved = false  # the desired time was not available to reserve
      reservation_status = "Request was not reserved because there were no open reservations that matched your desired time."
      # TODO: add code here to set up a scheduled try again request
    end
    self.save  # save the request and update the list of available times
    return reservation_status  # return the reservation status
  end
  
  # update the available reservation times close to the desired time
  def update_available_times
    agent = User.find(self.user_id).mechanize  # get the user's mechanize agent with the appropriate cookie-jar
    
    # try to get the restaurant page with reservation times
    restaurant_address = "http://www.opentable.com/opentables.aspx"
    restaurant_address += "?p=#{self.party_size}"
    restaurant_address += "&d=#{self.time.strftime("%-m/%e/%Y") + "%20" + self.time.strftime("%I:%M:%S") + "%20" + self.time.strftime("%p")}"
    restaurant_address += "&rid=#{self.restaurant.opentable_restaurant_id}&t=single"
    begin
      restaurant_page = agent.get(restaurant_address)
    rescue Exception => e
      self.opentable_parameters = { :shpu => "-1", :hpu => "-1", :rid => "-1", :d => "-1", :p => "-1", :pt => "-1", :i => "-1", :ss => "-1", :sd => "-1" }
      return
    end

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
    
    # try to get the profile page for the user
    agent = User.find(user_id).mechanize
    begin
      profile_page = agent.get("http://www.opentable.com/myprofile.aspx")
    rescue Exception => e
      return "Reservation was not canceled because there was a problem connecting with OpenTable servers.  Please try again."
    end

    # if one or more reservations are listed, find the desired reservation and try to cancel it
    if profile_page.parser.css("div.RestaurantName a").size > 0
      
      # loop through each reservation and save the index of the desired reservation
      index = -1
      profile_page.parser.css("div.RestaurantName a").each_with_index { |x, i| index = i if x.text == self.restaurant.name }
      if index != -1
        
        begin
          cancel_page = agent.get(profile_page.parser.css("div.C a")[index]['href'])
        rescue Exception => e
          return "Reservation was not canceled because there was a problem connecting with OpenTable servers.  Please try again."
        end
        
        cancel_form = cancel_page.form('Form1')
        submit_button = cancel_form.button_with(:name => 'btnCancelReso')
        
        begin
          done_page = agent.submit(cancel_form, submit_button)
        rescue Exception => e
          return "Reservation was not canceled because there was a problem connecting with OpenTable servers.  Please try again."
        end
        
        self.isReserved = false
        self.save
        reservation_status = "Reservation was successfully canceled."
      end
      
    else
      reservation_status = "Reservation was not canceled."
    end
    
    return reservation_status  # return the reservation status
  end
  
  # deletes all requests that do not link to valid restaurants
  def self.check_validity
    self.all.each { |request| request.destroy if request.restaurant.nil? }
  end
end