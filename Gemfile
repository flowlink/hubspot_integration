source 'https://rubygems.org'

gem 'httparty'
gem 'sinatra'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'endpoint_base', github: 'spree/endpoint_base'
gem 'unicorn'

group :test do
  gem 'simplecov', :require => false, :group => :test
  gem 'vcr'
  gem 'rspec'
  gem 'webmock'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rack-test'
  gem 'hub_samples', github: 'spree/hub_samples', require: 'hub/samples'
end

group :development do
  gem 'foreman'
end
