class UsersController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html, :js, :xml, :json
  
  def show
    @user = self.current_user
    Request.check_validity  # check all requests are valid before displaying them
    @requests = @user.requests.paginate(page: params[:page])
    respond_with @user
  end
end