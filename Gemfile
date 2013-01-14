source :rubygems

gem 'sinatra', '=1.3.3'
gem 'sinatra-contrib', :require => [
  'sinatra/content_for',
  'sinatra/namespace',
  'sinatra/config_file'
]
gem 'sinatra-flash', :require => 'sinatra/flash'
gem 'mysql'
gem 'json'
gem "dm-core", ">=1.2.0"
gem "dm-serializer", ">=1.2.0"
gem "dm-migrations", ">=1.2.0", :require => [
  'dm-migrations',
  'dm-migrations/migration_runner'
]
gem "dm-validations", ">=1.2.0"
gem "dm-constraints", ">=1.2.0"
gem "dm-types", ">=1.2.0"
gem "dm-mysql-adapter", ">=1.2.0"
gem 'multi_json'
gem 'addressable'
gem 'uuid'
gem 'gravatarify', ">= 3.1.0"
gem 'timetastic', '>= 0.1.4', :git => 'https://github.com/amireh/timetastic'
gem "pony"
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
# gem 'omniauth-twitter', '0.0.9'
gem 'omniauth-google-oauth2'

group :development do
  gem 'thin'
  # gem 'rake'
end

group :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-core'
  gem 'capybara-webkit', '>= 0.13.0', :git => 'https://github.com/thoughtbot/capybara-webkit'
  gem 'capybara', '>= 2.0.2'
  gem 'launchy'
end

group :production do
end