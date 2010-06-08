require "openid"
require 'openid/extensions/ax'
require 'openid/store/railscache'
require 'gapps_openid'

# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  
  before_filter :require_authentication, :only => [:destroy]
  
  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:email], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      user.load_contacts(true)
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      
      redirect_back_or_default('/messages')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:email]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def associate
    if request.post?
      user = User.authenticate(session[:email], params[:password])
      if user
        user.openid = session[:openid]
        user.save!
      
        self.current_user = user
        # Protects against session fixation attacks, causes request forgery
        # protection if user resubmits an earlier form using back
        # button. Uncomment if you understand the tradeoffs.
        # reset_session
        user.load_contacts(true)
      
        redirect_back_or_default('/messages')
        flash[:notice] = "Logged in successfully"
      else
        note_failed_signin
      end
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  def new_openid
  end
  
  def openid_start
    logout_keeping_session!
    return_to_url = '/messages'

    begin
      identifier = params[:identifier]
      identifier = identifier.split('@').last if identifier =~ /@/
      if identifier.nil?
        flash[:error] = "Please enter your OpenID information"
        render :action => 'new_openid'
        return
      end
      # Create the request      
      request = consumer.begin(identifier)
    rescue OpenID::OpenIDError => e
      flash[:error] = "Invalid OpenID identifier"
      render :action => 'new_openid'
      return
    end

    # Request attributes
    ax = OpenID::AX::FetchRequest.new
    ax.add(OpenID::AX::AttrInfo.new("http://axschema.org/contact/email", "email", true))
    ax.add(OpenID::AX::AttrInfo.new("http://axschema.org/namePerson/first", "firstname", true))
    ax.add(OpenID::AX::AttrInfo.new("http://axschema.org/namePerson/last", "last", true))
    request.add_extension(ax)

    return_to = openid_complete_url
    realm = root_url

    # Send request
    if request.send_redirect?(realm, return_to)
      redirect_to request.redirect_url(realm, return_to)
    else
      render :text => request.html_markup(realm, return_to)
    end
  end

  def openid_complete
    # Handle server response
    current_url = openid_complete_url
    parameters = params.reject{|k,v|request.path_parameters[k]}
    response = consumer.complete(parameters, current_url)
    case response.status
      when OpenID::Consumer::SUCCESS
        flash[:notice] = "Logged in successfully"
        ax = OpenID::AX::FetchResponse.from_success_response(response)
        email = ax.get_single("http://axschema.org/contact/email") 
        first_name = ax.get_single("http://axschema.org/namePerson/first") 
        last_name = ax.get_single("http://axschema.org/namePerson/last") 
        verified_email = trusted_provider?(response.endpoint.server_url)
        # Lookup by claimed ID or email
        user = find_or_create_user(response.display_identifier, email, first_name, last_name, verified_email)
        if user.present?
          self.current_user = user
          user.load_contacts(true)
          redirect_to '/messages'
        end
      when OpenID::Consumer::FAILURE
        flash[:error] = "Verification failed: #{response.message}"
        redirect_to :action => 'new'
      when OpenID::Consumer::SETUP_NEEDED
        flash[:alert] = "Immediate request failed - Setup Needed"
        redirect_to :action => 'new'
      when OpenID::Consumer::CANCEL
        flash[:alert] = "OpenID transaction cancelled."
        redirect_to :action => 'new'
      else
    end
  end

protected
  def trusted_provider?(endpoint_uri)
    parsed_uri = URI::parse(endpoint_uri)
    return parsed_uri.host =~ /.*google.com$/
  end

  def find_or_create_user(display_identifier, email, first_name, last_name, verified_email)
    user = User.find_by_openid(display_identifier)
    if user.nil?
      user = User.find_by_email(email)
      if user.present?
        if verified_email
          user.openid = display_identifier
          user.save!
        else 
          session[:openid] = display_identifier.to_s
          session[:email] = email
          render :action=>'associate'
          return
        end
      else 
        user = User.new
        user.name = "Unknown"
        user.name = "#{first_name} #{last_name}" unless first_name.nil? && last_name.nil?
        user.login = email
        user.email = email
        user.password = user.password_confirmation = User.make_token
        user.openid = display_identifier
        user.save!
        if verified_email
          user.activate!
        else
          redirect_back_or_default('/')
          return
        end
      end
    end
    user
  end
  
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  private

  # Construct the consumer
  def consumer
    if @consumer.nil?
      store = OpenID::Store::RailsCache.new
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end

end
