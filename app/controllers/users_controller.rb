class UsersController < ApplicationController
  before_filter :require_authentication, :except=>[:new, :create, :activate]
  before_filter :ensure_setup, :except=>[:new, :create, :activate]

  def index
    @organization = current_user.organization
    @users = @organization.users
  end

  def show
  end
  
  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    @user.login = @user.email
    
    success = @user && @user.save
    if success && @user.errors.empty?    
      @user.activate! # SJB - Disable verification
      self.current_user = @user #SJB - Auto login
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(edit_user_path(@user)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
  end
  
  #
  # Change user passowrd
  def change_password
  end

  #
  # Change user passowrd
  def change_password_update
      if User.authenticate(current_user.login, params[:old_password])
          if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
              current_user.password_confirmation = params[:password_confirmation]
              current_user.password = params[:password]
              
              if current_user.save!
                  flash[:notice] = "Password successfully updated"
                  redirect_to change_password_path
              else
                  flash[:alert] = "Password not changed"
                  render :action => 'change_password'
              end
               
          else
              flash[:alert] = "New Password mismatch" 
              render :action => 'change_password'
          end
      else
          flash[:alert] = "Old password incorrect" 
          render :action => 'change_password'
      end
  end  

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
end
