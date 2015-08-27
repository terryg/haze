class App < Sinatra::Base

  get '/' do
    assets = Asset.all(:order => [:created_at.asc])
    @urls = assets.map{|x| "https://s3.amazonaws.com/haze-assets/#{x.s3_fkey}"}
    haml :index
  end

end
