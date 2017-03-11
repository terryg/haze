require 'open-uri'
require 'rmagick'
require 'redis'
require './models/asset'

namespace :haze do
  
  desc "Makes an animated GIF from the individual images."
  task :make_gif do
    assets = Asset.all(:deleted.not => true, :type => "JPEG", :order => [:created_at.desc], :limit => 124)
    assets.reverse!

    filenames = []

    new_image = Magick::ImageList.new
    
    assets.each do |a|
      puts "INFO: #{a.id} -- #{a.created_at} -- #{a.url}"
      if a.url
        urlimage = open(URI.parse(a.url))
        new_image.from_blob(urlimage.read)
      end
    end
    
    puts "INFO: new_image length - #{new_image.length}"
    
    index = 0
    while index < assets.length
      puts "INFO: #{index} #{index.to_s.rjust(4, "0")} #{index % new_image.length}"
      new_image[index % new_image.length].write("tmp/haze_#{index.to_s.rjust(4, "0")}.png")
      index = index + 1
    end
 
    stamp = Time.now.to_i

    %x{convert -limit memory 256MiB -delay 20 -loop 0 tmp/haze_*.png tmp/#{stamp}.gif}

    fkey = Asset.store_on_s3(open("tmp/#{stamp}.gif", "rb"), "#{stamp}.gif")
    puts "INFO: #{fkey}"
    asset = Asset.new({:s3_fkey => fkey,
                       :type => "GIF",
                       :created_at => Time.now})
    if !asset.save
      asset.errors.each do |err|
        puts "ERR: #{err}"
      end
    else
      puts "INFO: saved asset #{asset.id}"
    end

    redis = Redis.new
      
    Asset.all(:type => "GIF").each do |a|
      if a.id != asset.id
        puts "INFO: doomed asset #{a.id}"
        a.delete_s3
        r = redis.del("assets:#{a.id}")
        puts "INFO: r -> #{r}"
        puts "INFO: done."
      end
    end
  end

end
