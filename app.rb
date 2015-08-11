require 'rubygems'
require 'sinatra'
require 'haml'

class App < Sinatra::Base

  get '/' do
    files = Dir.glob('/tmp/*.jpg')
    puts files
    haml :index
  end

end
