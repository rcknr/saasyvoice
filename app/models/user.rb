require 'digest/sha1'
require 'oauth/consumer'
class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  belongs_to :organization
  has_one :extension
  has_one  :google_oauth_token, :class_name=>"GoogleToken", :dependent=>:destroy
  
  #validates_presence_of     :login
  #validates_length_of       :login,    :within => 3..40
  #validates_uniqueness_of   :login
  #validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_presence_of     :name
  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  before_create :make_activation_code 

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation
  accepts_nested_attributes_for :extension


  # Activates the user in the database.
  def activate!
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def load_contacts(reload = false)
    client, options = oauth_client # For 3LO - [ google_oauth_token.client, {}]  
    return if client.nil?

    cache_key = "#{email}_contacts"
    values = Rails.cache.read(cache_key)
    if reload || values.nil?
      fetcher = Google::ContactsFetcher.new(client)
      values = fetcher.all_contacts(options)
      Rails.cache.write(cache_key, values)
      values.each do |c|
        c.phones.each do |p|
          Rails.cache.write("#{email}_contact_#{p.value}", c )
        end
      end unless values.nil?
    end
  end

  def all_contacts
    load_contacts
    Rails.cache.read("#{email}_contacts")
  end
  
  def contact_by_phone(phone)
    load_contacts
    Rails.cache.read("#{email}_contact_#{phone}")
  end

  def oauth_client
    client = google_oauth_token.client if google_oauth_token.present?
    options = {}
    if organization.present? && organization.from_marketplace?
      client, options = organization.oauth_client(email)
    end
    return [client, options]
  end
  
  protected
    
    def make_activation_code
        self.activation_code = self.class.make_token
    end


end
