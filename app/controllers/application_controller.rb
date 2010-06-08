# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  ActionView::Base.default_form_builder = MyFormBuilder
  ActionView::Base.field_error_proc = Proc.new { |tag, instance| "#{tag}" }

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  
  before_filter :check_marketplace
  
  protected

  def check_marketplace
    puts("HAVE MP=#{params[:marketplace]}")
    session[:marketplace] = true unless params[:marketplace].nil?
  end
  
  def require_authentication
    redirect_to :controller => 'home', :action => 'index' if current_user.nil?
  end
  
  def ensure_setup
    return if current_user.nil?
    if current_user.organization.nil?
      org = Organization.for_user(current_user)
      unless org.nil? 
        current_user.organization = org
        current_user.save(false)
      else
        redirect_to :controller => 'organizations', :action => 'new' if org.nil?
        return
      end
    end
    if current_user.extension.nil?
      redirect_to :controller => 'extensions', :action => 'new'
    end 
  end
  
end
