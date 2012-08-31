# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120822211448) do

  create_table "requests", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.integer  "party_size"
    t.datetime "time"
    t.boolean  "isReserved",           :default => false
    t.integer  "restaurant_id"
    t.string   "available_times"
    t.string   "opentable_parameters"
  end

  add_index "requests", ["user_id", "created_at"], :name => "index_requests_on_user_id_and_created_at"

  create_table "restaurants", :force => true do |t|
    t.string   "opentable_restaurant_id"
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "ZIP"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "restaurants", ["city"], :name => "index_restaurants_on_city"
  add_index "restaurants", ["name"], :name => "index_restaurants_on_name"
  add_index "restaurants", ["state"], :name => "index_restaurants_on_state"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name"
    t.string   "phone"
    t.string   "ot_id"
    t.text     "cookie_jar"
    t.string   "encrypted_password"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
