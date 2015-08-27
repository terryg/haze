class App < Sinatra::Base

  get '/' do
    assets = Asset.all(:s3_fkey.not => nil, :order => [:id.asc])
    @urls = assets.map{|x| "https://s3.amazonaws.com/haze-assets/#{x.s3_fkey}"}
    haml :index
  end

end
