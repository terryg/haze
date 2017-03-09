class App < Sinatra::Base

  get '/' do
    redis = Redis.new
    id = redis.get("assets:id:serial")
    puts "latest is #{id}"
    @asset = Asset.get(id.to_i)
    haml :index
  end

end
