source 'https://rubygems.org'
source 'https://rails-assets.org'

ruby '2.2.0'

gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-asset-pipeline', require: 'sinatra/asset_pipeline'
gem 'sinatra-contrib'
gem 'rack-contrib'
gem 'rack-cache'
gem 'mini_magick'

gem 'mongoid'
gem 'refile'
gem 'puma'
gem 'ejs'

gem 'activesupport'

gem 'uglifier'
gem 'andand'
gem 'sass'
gem 'dotenv'
gem 'aws-sdk', '~> 2'

gem 'image_optim'
gem 'image_optim_pack', require: false


group :development do
  gem 'heroku'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rack-livereload'
  gem 'guard'
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false

end

group :development, :test do
  gem 'pry'
  gem 'terminal-notifier-guard'
  gem 'terminal-notifier'
end

group :test do
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers', require: false
  gem 'database_cleaner', github: 'DatabaseCleaner/database_cleaner'
  gem 'simplecov', require: false
end

group :production do
  # gem 'rack-ssl'
  # gem 'newrelic_rpm'
  # gem 'newrelic_moped'
  # gem 'memcachier'
  # gem 'connection_pool'
  # gem 'dalli'
end
