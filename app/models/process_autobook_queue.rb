class ProcessAutobookQueue
  @queue = :autobook_requests
  @@redis = Redis.new
  
  def self.perform
    @@redis.set("processing_autobook_requests", 1)
    while true
      @@redis.smembers("autobook_requests").each do |request_id|
        request = Request.find(request_id.to_i)
        desired_time = request.time
        0.step(request.time_margin, 15) do |diff|
          break if request.isReserved
          if diff == 0
            Rails.logger.info "Trying to autobook a reservation at #{request.restaurant.name} at #{desired_time.strftime("%l:%M %p - %A, %B %e, %Y")}."
            Rails.logger.info request.try_reserve
            if request.isReserved
              request.time_margin = nil
              request.save
              @@redis.srem("autobook_requests", request_id)
              self.notify_user(request)
            end
          else
            Rails.logger.info "Trying to autobook a reservation with a time margin of #{diff} minutes and a desired time of #{desired_time.strftime("%l:%M %p - %A, %B %e, %Y")}."
            [-diff, diff].each do |df|
              break if request.isReserved
              total_min = desired_time.hour * 60 + desired_time.min + df
              new_hour = total_min / 60
              new_min = total_min % 60
              if new_hour >= 24
                new_day = desired_time.day + 1
                new_hour = new_hour - 24
              elsif new_hour < 0
                new_day = desired_time.day - 1
                new_hour = 24 - new_hour
              end
              request.time = request.time.change(:day => new_day, :hour => new_hour, :min => new_min)
              request.save
              Rails.logger.info "Currently attempting to book the reservation for #{request.time.strftime("%l:%M %p - %A, %B %e, %Y")}."
              Rails.logger.info request.try_reserve
              if request.isReserved
                request.time_margin = nil
                request.save
                @@redis.srem("autobook_requests", request_id)
                self.notify_user(request)
              end
            end
          end
        end
      end
      sleep 60
    end
  end
  
  def self.notify_user(request)
    message = Message.new(name: "Reservation Booker",
                          email: "reservationbooker@notify.levion.com",
                          subject: "Your reservation has been successfully autobooked at #{request.restaurant.name}",
                          body: "Dear #{User.find(request.user_id).name}\n\n" +
                                "Your reservation at #{request.restaurant.name} has been booked for " +
                                "#{request.time.strftime("%l:%M %p - %A, %B %e, %Y")}.  Thanks again for using " +
                                "Reservation Booker!\n\n" + 
                                "If you have any comments or concerns please feel free to contact us.")
    Mailer.new_message(message, User.find(request.user_id).email).deliver
  end
end