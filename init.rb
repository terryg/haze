require 'rubygems'

require 'sinatra'
require 'haml'
require 'dm-core'
require 'dm-validations'
require 'dm-redis-adapter'
require 'aws/s3'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, {:adapter => "redis"})

require './models/asset'

DataMapper.finalize

AWS::S3::Base.establish_connection!(
  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
)
