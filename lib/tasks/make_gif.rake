require 'net/http'
require 'uri'
require 'rmagick'
require 'redis'
require './models/asset'
namespace :haze do
  
  desc "Makes an animated GIF from the individual images."
  task :make_gif do
    assets = Asset.all

    filenames = []

    assets.each do |a|
      puts "INFO: #{a.url}"
      if a.url
        uri = URI.parse(a.url)
        Net::HTTP.start(uri.host) do |http|
          resp = http.get(uri.path)
          tempfile = Tempfile.new(a.s3_fkey)
          File.open(tempfile.path, "wb") do |f|
            f.write resp.body
          end
          filenames << tempfile.path
        end
      end
    end
    
    puts "INFO: #{filenames}"

    new_image = Magick::ImageList.new(*filenames)
    
    index = 0
    while index < assets.length
      new_image[index % new_image.length].write("tmp/haze_#{index.to_s.rjust(4, "0")}.png")
      index = index + 1
    end
 
    stamp = Time.now.to_i

    %x{convert -limit memory 256MiB -delay 15 -loop 30 tmp/haze_*.png tmp/#{stamp}.gif}

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


    Dir["tmp/*.png"].each do |f|
      File.delete f
    end

    Dir["tmp/*.jpg"].each do |f|
      File.delete f
    end

    Dir["tmp/*.gif"].each do |f|
      File.delete f
    end

  end

end
