class ApplicationController < ActionController::Base
  protect_from_forgery
  
  layout proc{ |controller| controller.params[:empty] ? "empty" : "application" }
  
  def after_sign_in_path_for(resource)
    user_path(resource[:id])
  end
  
  def after_sign_up_path_for(resource)
    user_path(resource[:id])
  end
  
end
