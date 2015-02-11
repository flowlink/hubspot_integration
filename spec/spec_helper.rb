require 'rubygems'
require 'bundler'

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', 'hubspot_endpoint.rb')
Dir["./spec/support/**/*.rb"].each {|f| require f}

Sinatra::Base.environment = 'test'

def app
  HubspotEndpoint
end

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

ENV['ENDPOINT_KEY'] = '123'