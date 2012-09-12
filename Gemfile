source 'https://rubygems.org'

gem 'rails', '3.2.6'
gem 'bootstrap-sass'
gem 'devise'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'soulmate'
gem 'resque', "~> 1.22.0"
gem 'resque-scheduler', require: 'resque_scheduler'
gem 'faker'
gem 'mechanize'
gem 'redis-store'
gem 'redis-rails'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'
platforms :ruby do 
  group :development, :test do
    gem 'mysql2'
    gem 'therubyracer'
  end
  group :production do
    gem 'pg'
  end
end

platforms :jruby do 
  gem 'activerecord-jdbc-adapter'
  gem 'jruby-openssl'
  gem 'jdbc-mysql'
  gem 'json'
  group :assets do
    gem 'therubyrhino'
  end
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'compass-rails'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'