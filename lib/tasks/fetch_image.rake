require 'net/http'
require './models/asset'
namespace :haze do
  
  desc "Fetches the current image from hazecam.net"
  task :fetch_image do
    url = URI.parse("http://www.hazecam.net/images/main/boston_right.jpg")
    Net::HTTP.start(url.host, url.port) do |http|
      resp, data = http.get(url.path, nil)
      stamp = Time.now.to_i

      target = File.join(File.dirname(__FILE__), "../../tmp/#{stamp}.jpg")

      open(target, "wb") { |file| file.write(resp.body)}

      fkey = Asset.store_on_s3(open(target, "rb"), "#{stamp}.jpg")
      asset = Asset.new({:s3_fkey => fkey, :created_at => Time.now})
      if !asset.save
        asset.errors.each do |err|
          puts "ERR: #{err}"
        end
      else
        puts "INFO: saved asset #{asset.id}"
      end
    end

    assets = Asset.all(:created_at.lt => (Time.now - 3*60*60))
    assets.each do |a|
      puts "INFO: doomed asset #{asset.id}"
      a.destroy
    end
  end
end
