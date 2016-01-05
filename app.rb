class App < Sinatra::Base

  get '/' do
    assets = Asset.all(:s3_fkey.not => nil, :order => [:created_at.asc])
    @urls = assets.map{|x| "#{x.url}"}
    haml :index
  end

end
