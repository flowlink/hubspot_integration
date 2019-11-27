source 'https://rubygems.org'

gem 'httparty'
gem 'sinatra'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'endpoint_base', github: 'flowlink/endpoint_base'
gem 'unicorn'

group :test do
  gem 'simplecov', :require => false, :group => :test
  gem 'vcr'
  gem 'webmock'
  gem 'rspec'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rack-test'
end

group :development do
  gem 'foreman'
  gem 'shotgun'
end

group :development, :test do
  gem 'pry-byebug'
end
