require 'net/http'
namespace :haze do
  
  desc "Fetches the current image from hazecam.net"
  task :fetch_image do
    url = URI.parse("http://www.hazecam.net/images/main/boston_right.jpg")
    Net::HTTP.start(url.host, url.port) do |http|
      resp, data = http.get(url.path, nil)
      stamp = Time.now.to_i
      open( File.join(File.dirname(__FILE__), "../../tmp/#{stamp}.jpg"), "wb") { |file| file.write(resp.body) }
    end
  end
end