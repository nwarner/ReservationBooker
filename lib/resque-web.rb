require 'resque_scheduler'
require 'resque_scheduler/server'
require 'resque' # include resque so we can configure it

Resque.redis = "localhost:6379" # tell Resque where redis lives
Resque.schedule = YAML.load_file("config/resque_schedule.yml")
