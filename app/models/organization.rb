class Organization < ActiveRecord::Base
  include TwilioClient
  include AuthenticatedSystem
  
  has_many :users, :autosave =>true
  has_one :phone_number
  
  validates_presence_of     :name
  validates_length_of       :name,    :within => 3..40
  validates_length_of       :domain,  :within => 3..255, :allow_blank =>true, :allow_nil => true
  
  attr_accessible :name, :domain
  
  # Match a user to an organization, either by common domain or by presence of an invitation
  def self.for_user(user)
    org = Organization.find_by_domain(user.email.split('@').last)
    return org unless org.nil?
    
    invite = Invitation.find_by_email(user.email)
    return invite.organization unless invite.nil?
    
    nil
  end
  
  def oauth_client(requestor = nil)
    options = {}
    options['xoauth_requestor_id'] = requestor unless requestor.nil?
    oauth_consumer = OAuth::Consumer.new(
      OAUTH_CREDENTIALS[:google_marketplace][:key], 
      OAUTH_CREDENTIALS[:google_marketplace][:secret])
    client = OAuth::AccessToken.new(oauth_consumer)
    return [client, options]
  end
  
  def before_create
    if phone_number.nil?
      p = allocateNumber(name)
      build_phone_number(:number => p)
    end
  end
  
  def after_create
    if from_marketplace?
      client, options = oauth_client()    
      fetcher = Google::UserFetcher.new(client, domain)
      entries = fetcher.all_users(options)
      entries.each do |user_entry|
        user = User.new
        user.name = user_entry['name']
        user.login = user_entry['email']
        user.email = user_entry['email']
        user.password = user.password_confirmation = User.make_token
        user.organization = self
        user.save
      end
    end
  end
end
