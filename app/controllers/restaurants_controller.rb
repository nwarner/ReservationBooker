class RestaurantsController < ApplicationController
  before_filter :authenticate_user!
  
  def autocomplete_restaurant_name
    respond_to do |format|
      format.json { render :json => Restaurant.search_name(params['term']) }
    end
  end
  
  def autocomplete_restaurant_city
    respond_to do |format|
      format.json { render :json => Restaurant.search_city(params['term']) }
    end
  end
  
  def search
    states = %w(0 AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO
                   MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY)
                   
    # save the search terms
    @name = params[:restaurant_name].nil? ? "" : params[:restaurant_name]
    @city = params[:restaurant_city].nil? ? "" : params[:restaurant_city]
    @state = (states[params[:state].to_i] == "0") ? "" : states[params[:state].to_i]
    
    # get the applicable restaurants and paginate the results
    @restaurants = Restaurant.search(@name, @city, @state).paginate(page: params[:page], per_page: 10)
    
    # if this was called by the requests controller, get the appropriate request
    @request = Request.find_by_id(params[:request_id]) if params[:request_id]
    
    # respond appropriately to browser requests
    respond_to do |format|
      format.html
      format.js
    end
  end
end
