class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def show
    @user = self.current_user
    @requests = @user.requests.paginate(page: params[:page])
  end
end