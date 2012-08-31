task :book_reservation do

  # test Restaurant:
  #
  rest_id = 33454
  rest_name = "Ariccia Italian Trattoria & Bar"
  party_size = 2
  time = Time.utc(2012,8,15,23,59,59)


  # login to OpenTable.com
  puts "Currently accessing the login page..."

  agent = Mechanize.new
  login_page = agent.get("https://secure.opentable.com/login.aspx")
  login_form = login_page.form('Login')
  login_form.txtUserEmail = "solokin1@gmail.com"
  login_form.txtUserPassword = "foobar"
  login_form.checkbox_with(:name => 'chkRemember').check
  new_page = agent.submit(login_form, login_form.buttons.first)

  # browse to the required restaurant
  puts "Currently accessing the restaurant page for #{rest_name}..."
  restaurant_address = "http://www.opentable.com/opentables.aspx"
  restaurant_address += "?p=#{party_size}"
  restaurant_address += "&d=#{time.strftime("%-m/%e/%Y") + "%20" + time.strftime("%l:%M:%S") + "%20" + time.strftime("%p")}"
  restaurant_address += "&rid=#{rest_id}&t=single"
  restaurant_page = agent.get(restaurant_address)

  puts restaurant_page.title
  puts restaurant_page.parser.css("ul.ResultTimes").inner_html
  #pp restaurant_page

 # https://secure.opentable.com/details.aspx?iid=10&shpu=1&hpu=864109026&rid=75403&d=8/13/2012%208:30:00%20PM&p=2&pt=100&i=0&ss=1&sd=8/13/2012%209:00:00%20PM&Q=IID

    #location_page.parser.css("a.r").each do |restaurant_link|
     # puts "Currently saving #{restaurant_link.text}"
     # restaurant_names << restaurant_link.text
     # restaurant_page = agent.get("http://www.opentable.com/#{restaurant_link["href"]}")
     # address_block = restaurant_page.parser.css("span#ProfileOverview_lblAddressText").inner_html
    
      # if we have more than two <br>'s in the address block
     # if (address_block.index("<") != address_block.rindex("<"))
      #  address = address_block[/\A(.*?)\</][0...-1]
      #  address_block.slice! (address + "<br>")
      #  address += (" " + address_block[/\A(.*?)\</][0...-1])
      # if we just have one <br>
     # else
      #  address = address_block[/\A(.*?)\</][0...-1]
      #  address_block.slice! address_block[/\A(.*?)\</][0...-1]
      #end
     # restaurant_addresses << address
     # restaurant_cities << address_block[/\>(.*?)\,/][1...-1]
     # restaurant_states << address_block[/\,(.*?)\z/][2...4]
     # restaurant_zips << address_block[/\,(.*?)\z/][6...11]
    #end

    #location_page.parser.css("div.rinfo").each do |rest_id|
     # restaurant_ids << rest_id["rid"]
   # end
  #end
end