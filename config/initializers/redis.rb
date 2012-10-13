REDIS_URI =  URI.parse( Rails.env == "production" ? ENV["REDISTOGO_URL"] : "redis://127.0.0.1:6379/" )
REDIS = Redis.new(:host => REDIS_URI.host, :port => REDIS_URI.port, :password => REDIS_URI.password)
Resque.redis = REDIS
Redis.current = REDIS
$redis = Redis.new(:host => REDIS_URI.host, :port => REDIS_URI.port, :password => REDIS_URI.password)