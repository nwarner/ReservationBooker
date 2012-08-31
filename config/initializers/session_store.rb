# Be sure to restart your server when you modify this file.

redis_uri = ( Rails.env == "production" ? ENV["REDISTOGO_URL"] : "redis://127.0.0.1:6379/" )
ReservationBooker::Application.config.session_store :redis_store, { :servers => redis_uri + "res:session", :expire_in => 3600 }

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# ReservationBooker::Application.config.session_store :active_record_store