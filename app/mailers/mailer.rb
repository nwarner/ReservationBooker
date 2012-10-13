class Mailer < ActionMailer::Base
  default from: "reservationbooker@notify.levion.com"
  default to: "niko@levion.com"
  
  def new_message(message, recipient="niko@levion.com")
    @message = message
    mail(to: recipient, subject: "[Reservation Booker] #{message.subject}")
  end
end
