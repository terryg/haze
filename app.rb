class App < Sinatra::Base

  get '/' do
    @asset = Asset.first(:s3_fkey.not => nil,
                         :type => "GIF", 
                         :order => [:created_at.desc])
    haml :index
  end

end
