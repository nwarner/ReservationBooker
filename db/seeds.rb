# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

1000.times do
  Restaurant.create name: "#{Faker::Company.name}",
                    address: "#{Faker::Address.street_address}",
                    city: "#{Faker::Address.city}",
                    state: "#{Faker::Address.us_state}",
                    ZIP: "#{Faker::Address.zip_code}"
end