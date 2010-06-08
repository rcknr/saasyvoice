# Methods added to this helper will be available to all templates in the application.
require 'phone'

module ApplicationHelper
  def format_phone(phone)
    Phone.parse(phone).format(:us) rescue phone
  end
  
  def has_integration?
    ENV['GOOG'].present?
  end
  
  def has_oauth?
    @user.organization.from_marketplace? || @user.google_oauth_token.present?    
  end
end
