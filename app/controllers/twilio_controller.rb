require 'twiliolib'

class TwilioController < ApplicationController
  skip_before_filter :verify_authenticity_token
  #before_filter :verify_signature
  before_filter :lookup_phone
  
  def start
    @response = Twilio::Response.new
    @response.addSay("Please enter your extension followed by pound.", :voice => "woman")
    @response.addGather(:numDigits => "2", :finishOnKey => '#', :action => url_for(:action => "extension"))
    render :xml => @response.respond
  end
  
  def extension
    #TODO - Validate extension
    @response = Twilio::Response.new
    @extension = @phone.extensions.find_by_number(params[:Digits])
    if @extension.nil?
      @response.addSay("Invalid extension, try again.", :voice => "woman")
      @response.addSay("Please enter your extension followed by pound.", :voice => "woman")
      @response.addGather(:numDigits => "2", :finishOnKey => '#', :action => url_for(:action => "extension"))
    elsif @extension.forward_to.present?
      @response.addSay("Please wait while we forward your call.", :voice => "woman")
      @response.addDial(@extension.forward_to)
    else   
      @response.addSay("Leaving message for #{@extension.user.name}.", :voice => "woman")
      @response.addSay('Press # to end your call or hang up.', :voice => "woman")
      @response.addRecord(:timeout => "15", :maxLength => "120", 
        :finishOnKey => '#', :action => url_for(:action => "record", :extension => params[:Digits]))
    end
    render :xml => @response.respond
  end
  
  def record
    @extension = @phone.extensions.find_by_number(params[:extension])
    message = @extension.messages.build(:guid => params[:CallGuid], :from => "+1#{params[:Caller]}", 
      :url => params[:RecordingUrl], :duration => params[:Duration])
    message.save!
    @response = Twilio::Response.new
    @response.addSay("Thank you.", :voice => "woman")
    @response.addHangup()
    render :xml => @response.respond
  end
  
  private
  
  def verify_signature
    utils = Twilio::Utils.new(TWILIO_SID, TWILIO_TOKEN)
    signature = @_request.headers['HTTP_X_TWILIO_SIGNATURE']
    twilio_params = {}
    if @_request.post?
        twilio_params = params.inject({}) do |h, (key,value)|
            h[key] = value unless key =~ /^(controller|active|action)/
        end
    end
    render :text => "Invalid signature", :status => 401 unless utils.validateRequest(signature, @_request.url, twilio_params)    
  end
  
  def lookup_phone
    num = "+1#{params[:Called]}"
    @phone = PhoneNumber.find_by_number(num)
    render :text => "Invalid phone number", :status => 500 if @phone.nil?
  end
end