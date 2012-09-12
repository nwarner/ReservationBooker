class Restaurant < ActiveRecord::Base
  has_many :requests
  
  attr_accessible :ZIP, :address, :city, :name, :opentable_restaurant_id, :state
  
  validates :opentable_restaurant_id, presence: true
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :ZIP, presence: true
  
  default_scope order: "restaurants.name ASC"
  
  # returns restaurants matching to a name, city, and/or state
  def self.search(name, city, state)
    if name.empty? && city.empty? && state.empty?
      self
    elsif name.empty? && city.empty?
      self.where("state = ?", state)
    elsif name.empty? && state.empty?
      self.where("city = ?", city)
    elsif city.empty? && state.empty?
      self.where("name = ?", name)
    elsif name.empty?
      self.where("city = ? AND state = ?", city, state)
    elsif city.empty?
      self.where("name = ? AND state = ?", name, state)
    elsif state.empty?
      self.where("name = ? AND city = ?", name, city)
    else
      self.where("name = ? AND city = ? AND state = ?", name, city, state)
    end
  end
  
  # searches for restaurant name matches
  def self.search_name(term)
    matches = Soulmate::Matcher.new('restaurant_name').matches_for_term(term)
    matches.collect {|match| {"id" => match["id"], "label" => match["term"], "value" => match["term"] } }
  end
  
  # searches for restaurant city matches
  def self.search_city(term)
    matches = Soulmate::Matcher.new('restaurant_city').matches_for_term(term)
    matches.collect {|match| {"id" => match["id"], "label" => match["term"], "value" => match["term"] } }
  end

  # reloads restaurant names and cities into redis for autocomplete
  def self.reindex
    # load restaurant names into soulmate and get unique city names
    cities = []
    self.all.each do |restaurant|
      loader = Soulmate::Loader.new("restaurant_name")
      loader.add("term" => restaurant.name, "id" => restaurant.id)
      cities.push(restaurant.city)
    end
    
    # get unique city names
    cities.uniq!
    
    # load city names into soulmate
    cities.each_with_index do |city, index|
      loader = Soulmate::Loader.new("restaurant_city")
      loader.add("term" => city, "id" => index)
    end
  end
end