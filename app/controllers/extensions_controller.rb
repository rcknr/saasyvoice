class ExtensionsController < ApplicationController
  before_filter :require_authentication
  before_filter :check_extension, :only=>[:new, :create]
  
  # GET /extensions
  # GET /extensions.xml
  def index
    @organization = current_user.organization
    @extensions = @organization.phone_number.extensions

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @extensions }
    end
  end

  # GET /extensions/:id
  # GET /extensions/:id.xml
  def show
    @organization = current_user.organization
    @extension = @organization.phone_number.extensions.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @extension }
    end
  end

  # GET /extensions/new
  # GET /extensions/new.xml
  def new
    @organization = current_user.organization
    @extension = Extension.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @extension }
    end
  end

  # GET /extensions/1/edit
  def edit
    @organization = current_user.organization
    @extension = @organization.phone_number.extensions.find(params[:id])
  end

  # POST /extensions
  # POST /extensions.xml
  def create
    @organization = current_user.organization
    num = @organization.phone_number.next_extension
    @extension = @organization.phone_number.extensions.build(:forward_to =>params[:extension][:forward_to])
    @extension.number = num
    @extension.user = current_user

    respond_to do |format|
      if @extension.save
        flash[:notice] = 'Extension was successfully created.'
        format.html { redirect_to(:controller => 'messages', :action => 'index') }
        format.xml  { render :xml => @extension, :status => :created, :location => @extension }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @extension.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /extensions/1
  # PUT /extensions/1.xml
  def update
    @organization = current_user.organization
    @extension = @organization.phone_number.extensions.find(params[:id])

    respond_to do |format|
      if @extension.update_attributes(params[:extension])
        flash[:notice] = 'Extension was successfully updated.'
        format.html { redirect_to(edit_user_path(current_user)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @extension.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /extensions/1
  # DELETE /extensions/1.xml
  def destroy
    @organization = current_user.organization
    @extension = @organization.phone_number.extensions.find(params[:id])
    @extension.destroy

    respond_to do |format|
      format.html { redirect_to(extensions_url) }
      format.xml  { head :ok }
    end
  end

  private
  
  def check_extension
    redirect_to edit_extension_path(current_user.extension) unless current_user.extension.nil?
  end
  
end
