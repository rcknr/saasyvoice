# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_voicemail_session',
  :secret      => '99f43434b515827c147e05ee9a2edaa5c42dd48428137baf1a7bd14a95992a331132eea6d3987196a817b19f2f67f78d5b6f2bdfcd188de8393bfbef1e6e2c02'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
