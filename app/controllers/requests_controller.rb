class RequestsController < ApplicationController
  before_filter :authenticate_user!
  
  # show a request
  def show
    @request = Request.find(params[:id])
  end

  # try to reserve a request
  def reserve
    @request = Request.find(params[:id])
    status = @request.try_reserve
    if @request.isReserved
      flash[:success] = status
    else
      flash[:alert] = status
    end
    respond_to do |format|
      format.html { redirect_to user_path(current_user.id) }
    end
  end

  # try to cancel a request
  def cancel
    @request = Request.find(params[:id])
    status = @request.cancel_reservation
    if not @request.isReserved
      flash[:success] = status
    else
      flash[:alert] = status
    end
    respond_to do |format|
      format.html { redirect_to user_path(current_user.id) }
    end
  end
  
  # create a new request
  def create
    @request = current_user.requests.build(params[:request])
    if @request.save
      status = @request.try_reserve
      if not @request.isReserved
        flash[:alert] = status
      else
        flash[:success] = status
        session[:open_request] = true
      end
      session[:open_request] = true
    end
    respond_to do |format|
      format.js
    end
  end
  
  # delete a request and cancel the reservation if active
  def destroy
    @request = current_user.requests.find_by_id(params[:id])
    if !(@request.nil?)
      if @request.isReserved
        status = @request.cancel_reservation
        if !@request.isReserved
          flash[:success] = status + "\nReservation request was successfully deleted."
        else
          flash[:alert] = "Reservation request was successfully deleted but " + status.downcase
        end
      else
        flash[:success] = "Reservation request was successfully deleted."
      end
      @request.destroy
    end
    respond_to do |format|
      format.html { redirect_to user_path(current_user.id) }
    end
  end
  
  # delete all requests and try to cancel their reservations
  def delete_all
    error_occurred = false
    Request.all.each do |request|
      request.cancel_reservation
      if request.isReserved
        error_occurred = true
      else
        request.destroy
      end
    end
    if not error_occurred
      flash[:success] = "All reservation requests were successfully deleted."
    else
      flash[:alert] = "Some reservation requests could not be canceled."
    end
    respond_to do |format|
      format.html { redirect_to user_path(current_user.id) }
    end
  end
end