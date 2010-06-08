require 'rubygems'
require 'twiliolib'
require 'rexml/document'
require 'phone'

module TwilioClient
  FIXED_NUM = "+18776601798"
  
  def allocateNumber(company)
    return FIXED_NUM unless FIXED_NUM.nil?
    
    twilio_api = Twilio::RestAccount.new(TWILIO_SID, TWILIO_TOKEN)
    params = {
      'FriendlyName' => company,
      'VoiceCallerIdLookup' => 'true',
      'Url' => url_for(:controller => 'twilio', :action => 'start')
    }
    resp = twilio_api.request("/#{TWILIO_VERSION}/Accounts/#{TWILIO_SID}/IncomingPhoneNumbers/TollFree", 'POST', params)
    resp.error! unless resp.kind_of? Net::HTTPSuccess
    extractor = PhoneNumberExtractor.new
    extractor.parseResponse(resp.body)
  end
  
  class PhoneNumberExtractor
    def parseResponse(xml)
      doc = REXML::Document.new(xml)
      p = doc.elements.to_a("//PhoneNumber").first.text
      return Phone.parse("+1#{p}").to_s
    end
  end

end
