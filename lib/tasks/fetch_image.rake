require 'net/http'
require 'redis'
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

      md5sum = Asset.calc_md5sum(target)
      
      if Asset.last.md5sum != md5sum
        fkey = Asset.store_on_s3(open(target, "rb"), "#{stamp}.jpg")
        asset = Asset.new({:s3_fkey => fkey, :created_at => Time.now})
        if !asset.save
          asset.errors.each do |err|
            puts "ERR: #{err}"
          end
        else
          puts "INFO: saved asset #{asset.id}"
        end
      else
        puts "INFO: md5sum of last Asset is the same (#{md5sum})"
      end
      
      redis = Redis.new
      
      assets = Asset.all(:created_at.lt => (Time.now - 3*60*60), :fields => [:id, :s3_fkey, :created_at, :deleted])
      assets.each do |a|
        puts "INFO: doomed asset #{a.id}"
        a.delete_s3
        r = redis.del("assets:#{a.id}")
        puts "INFO: r -> #{r}"
        puts "INFO: done."
      end
      
    end
  end

end
