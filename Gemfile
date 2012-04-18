source 'https://rubygems.org'

gem 'hqmf-parser', :git => 'https://github.com/pophealth/hqmf-parser.git', :branch => 'develop'
#gem 'hqmf-parser', path: '../hqmf-parser'
gem 'hqmf2js', :git => 'https://github.com/pophealth/hqmf2js.git', :branch => 'bonnie'

gem 'rails', '3.2.2'
gem 'jquery-rails'

gem 'devise'
gem 'foreman'
gem 'cancan'
gem 'factory_girl'

gem "mongo"
gem "mongoid"
gem "bson"
gem 'bson_ext'

gem 'simple_form'

gem 'pry'
gem 'pry-nav'

group :test, :develop do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'cover_me'
  gem 'minitest'
  gem 'mocha', :require => false
  gem 'spork', "~> 0.9.0"
  gem 'rb-inotify' if RUBY_PLATFORM.downcase.include?("linux")
  gem 'rb-fsevent', "~> 0.9.0" if RUBY_PLATFORM.downcase.include?("darwin")
  gem 'guard', "~> 1.0.1"
  gem 'guard-spork', "~> 0.5.2"
  gem 'guard-minitest', "~> 0.5.0"
  gem 'spork-testunit', "~> 0.0.8"
end

group :production do
  gem 'therubyracer', :platforms => [:ruby, :jruby]
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
