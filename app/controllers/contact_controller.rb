class ContactController < ApplicationController
  def new
    @message = Message.new
  end
  
  def create
    @message = Message.new(params[:message])
    
    if @message.valid?
      Mailer.new_message(@message).deliver
      flash.now[:success] = "Your feedback was successfully sent.  We will address your concerns as soon as possible!"
    else
      flash.now[:error] = "There was a problem submitting your feedback.  Please check that you've filled out all required fields and try again."
    end
    respond_to do |format|
      format.html { render 'new' }
    end
  end
end
