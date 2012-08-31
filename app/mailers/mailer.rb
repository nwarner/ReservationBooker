class Mailer < ActionMailer::Base
  
  default from: "reservationbooker@notify.levion.com"
  default to: "niko@levion.com"
  
  def new_message(message)
    @message = message
    mail(subject: "[Reservation Booker] #{message.subject}")
  end
  
end
