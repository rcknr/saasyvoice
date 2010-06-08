require 'rubygems'
require 'rexml/document'
require 'rexml/element'
require 'rexml/xpath'
require 'oauth'
require 'phone'

module Google
  
  class Contact < Struct.new(:name, :phones, :emails)
  end
  
  class ContactProperty < Struct.new(:rel, :value)
  end
  
  class GoogleClient
    def initialize(token, base_url)
      @token = token
      @base_url = base_url
    end
    
    def url(options={})
      url = @base_url
      url += "?#{options.to_query}" unless options.empty?
      url
    end
    
    def get_feed(options, &block)
      response = @token.request(:get, url(options))
      return unless response.is_a?(Net::HTTPSuccess)
      feed = REXML::Document.new(response.body)
      results = []
      feed.elements.each('//entry') do |entry|
        result = yield entry
        results << result
      end
      results
    end
  end
      
  class ContactsFetcher < GoogleClient
    def initialize(token)
      super token, 'https://www.google.com/m8/feeds/contacts/default/full'
    end

    def all_contacts(options = {})
      options = { 'max-results' => 1000 }.merge(options)
      get_feed(options) do |entry|
        parse_entry(entry)
      end
    end

    protected

    def normalize_phone(num)
      num = Phone.normalize(num)
      num = "+#{num}" if num =~ /^1/
      num = "0#{num}" unless num =~ /^[0+]/
      num
    end
    
    def parse_entry(entry)
      contact = Contact.new
      contact.phones = []
      contact.emails = []
      contact.name = entry.elements["title"].text
      entry.elements.each("gd:phoneNumber") do |e|
        rel = e.attribute('rel').value.split('#').last rescue ''
        phone = Phone.parse(normalize_phone(e.text), :country_code => "1") rescue nil
        contact.phones << ContactProperty.new(rel, phone.to_s) unless phone.nil?
      end
      entry.elements.each("gd:email") do |e|
        rel = e.attribute('rel').value.split('#').last rescue ''
        contact.emails << ContactProperty.new(rel, e.attribute('address').value)
      end
      contact
    end
  end
  
  class UserFetcher < GoogleClient
    def initialize(token, domain)
      super token, "https://apps-apis.google.com/a/feeds/#{domain}/user/2.0"
      @domain = domain
    end

    def all_users(options = {})
      get_feed(options) do |entry|
        user = Hash.new
        name_element = entry.elements["apps:name"]
        login_element = entry.elements["apps:login"]
        user['name'] = "#{name_element.attribute('givenName').value} #{name_element.attribute('familyName').value}"
        user['email'] = "#{login_element.attribute('userName')}@#{@domain}"
        user
      end
    end
  end
end
