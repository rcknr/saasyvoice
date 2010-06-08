class MessagesController < ApplicationController
  before_filter :ensure_setup
  before_filter :require_authentication

  # GET /messages
  # GET /messages.xml
  def index
    @user = current_user
    @messages = current_user.extension.messages

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @user = current_user
    @message = current_user.extension.messages.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @user = current_user
    @message = current_user.extension.messages.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
    end
  end
end
