class App < Sinatra::Base

  get '/' do
    @asset = Asset.first(:s3_fkey.not => nil,
                         :type => "GIF", 
                         :order => [:created_at.asc])
    haml :index
  end

end
