require 'digest/md5'

class Asset
  include DataMapper::Resource

  property :id, Serial, :index => true
  property :s3_fkey, String
  property :created_at, DateTime
  property :deleted, Boolean, :default => false
  property :md5sum, String
  property :type, String
  validates_presence_of :s3_fkey, :created_at

  after :create do
    fname = 'tmp/' + self.s3_fkey
    self.md5sum = Asset.calc_md5sum(fname)
    save_self(false)
  end

  def self.calc_md5sum(fname)
    Digest::MD5.hexdigest(File.read(fname))
  end

  def self.s3_bucket
    ENV['S3_BUCKET_NAME']
  end

  def self.store_on_s3(temp_file, filename)
    value = (0...16).map{(97+rand(26)).chr}.join
    ext = File.extname(filename)
    fkey = value  + ext
    fname = 'tmp/' + fkey
    File.open(fname, "w") do |f|
      f.write(temp_file.read)
    end

    AWS::S3::S3Object.store(fkey, open(fname), self.s3_bucket)
    return fkey
  end

  def delete_s3
    puts "INFO: Asset #{self.id} exists with S3 #{self.s3_fkey}? #{AWS::S3::S3Object.exists?(self.s3_fkey, self.class.s3_bucket)}"
    AWS::S3::S3Object.delete(self.s3_fkey, self.class.s3_bucket)
    puts "INFO: delete_s3 done."
  end

  def url
    "https://s3.amazonaws.com/#{self.class.s3_bucket}/#{self.s3_fkey}"
  end


end
