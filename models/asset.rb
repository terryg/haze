class Asset
  include DataMapper::Resource

  property :id, Serial
  property :s3_fkey, String
  property :created_at, DateTime

  validates_presence_of :s3_fkey, :created_at

  def self.store_on_s3(temp_file, filename)
    value = (0...16).map{(97+rand(26)).chr}.join
    ext = File.extname(filename)
    fkey = value  + ext
    fname = 'tmp/' + fkey
    File.open(fname, "w") do |f|
      f.write(temp_file.read)
    end

    AWS::S3::S3Object.store(fkey, open(fname), ENV['S3_BUCKET_NAME'])
    return fkey
  end

  def destroy
    s3 = AWS::S3.new
    obj = s3.buckets[ENV['S3_BUCKET_NAME']].objects[self.s3_fkey]
    obj.delete
    super
  end

end