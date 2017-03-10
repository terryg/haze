require 'open-uri'
require 'redis'
require './models/asset'
namespace :haze do
  
  desc "Fetches the current image from hazecam.net"
  task :fetch_image do
    jpg0 = Asset.fetch("http://www.hazecam.net/images/main/boston_left.jpg")
    jpg1 = Asset.fetch("http://www.hazecam.net/images/main/boston_right.jpg")
    
    stamp = Time.now.to_i

    puts "XXXXX convert +append #{jpg0} #{jpg1} tmp/haze#{stamp}.jpg"
    
    %x{convert +append #{jpg0} #{jpg1} tmp/haze#{stamp}.jpg}

    md5sum = Asset.calc_md5sum("tmp/haze#{stamp}.jpg")
      
    if Asset.last.nil? or Asset.last.md5sum != md5sum
      fkey = Asset.store_on_s3(open("tmp/haze#{stamp}.jpg", "rb"),
                               "#{md5sum}.jpg")
      asset = Asset.new({:s3_fkey => fkey,
                         :type => "JPEG",
                         :created_at => Time.now})
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
      
    Asset.all(:created_at.lt => (Time.now - 24*60*60),
              :type => "JPEG").each do |a|
      puts "INFO: doomed asset #{a.id}"
      a.delete_s3
      r = redis.del("assets:#{a.id}")
      puts "INFO: r -> #{r}"
      puts "INFO: done."
    end
  end

end
