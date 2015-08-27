class App < Sinatra::Base

  get '/' do
    files = Dir.glob('./public/images/*.jpg')
    files.sort!
    @files = files.map{|x| File.basename(x)}
    haml :index
  end

end
