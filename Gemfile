source 'https://rubygems.org'

gem 'hqmf-parser', '~> 1.1.0'
gem 'hqmf2js', '~> 1.1.0'
gem 'hquery-patient-api', '~> 1.0.0'
gem 'health-data-standards', '~> 2.2.1'
gem 'test-patient-generator', '~> 1.1.0'
gem 'quality-measure-engine', '~> 2.2.0'
gem 'qrda_generator', '~> 1.0.1'

gem 'rails', '3.2.9'
gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'devise'
gem 'foreman'
gem 'cancan'
gem 'factory_girl'
gem 'text'
gem 'rubyXL'

gem "mongoid", '~> 3.0.9'

gem 'simple_form'
gem 'coderay'   # for javascript syntax highlighting

gem 'pry'
gem 'pry-nav'
gem 'pry-rescue'

group :test, :develop do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'cover_me'
  gem 'minitest'

  # spork and autotest allow you to run tests when you save a file.
  # run `spork` in one terminal from the project root.
  # run `bundle exec autotest -cf` in one terminal from the project root.
  # Then edit test files or app/* or lib/* and watch tests run automatically on save.
  gem 'spork'   # Spork caches rails so tests run fast.
  # Run 'bundle exec autotest' to rerun relevant tests whenever a file/test is changed.
#  gem 'autotest-standalone' # The file '.autotest' makes sure the tests are run via test server (spork).
#  gem 'autotest-rails-pure' # -pure gives us autotest without ZenTest gem.
#  gem 'autotest-fsevent'    # react to filesystem events, save your CPU  
  gem 'spork-minitest'
end

group :production do
  gem 'libv8', '~> 3.11.8.3'
  gem 'therubyracer', '~> 0.11.0beta5', :platforms => [:ruby] # 10.8 mountain lion compatibility
  gem 'therubyrhino', :platforms => [:jruby] # 10.8 mountain lion compatibility
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
