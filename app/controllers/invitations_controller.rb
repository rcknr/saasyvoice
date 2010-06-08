class InvitationsController < ApplicationController
  before_filter :require_authentication

  # render new.rhtml
  def new
    @organization = current_user.organization
    logger.info("Org = #{@organization}")
    @invitation = Invitation.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @invitation }
    end
    
  end
  
  def create
    @organization = current_user.organization
    @invitation = Invitation.new(params[:invitation])
    @invitation.organization = @organization
    respond_to do |format|
      if @invitation.save
        flash[:notice] = 'Invitation was successfully created.'
        format.html { redirect_to(users_path) }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

end
