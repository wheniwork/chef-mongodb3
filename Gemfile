source 'https://rubygems.org'

gem 'berkshelf'

gem 'chefspec'
gem 'foodcritic'
gem 'rubocop'
gem 'mongo', '~> 2.2'

# For bumping versions
gem 'thor'
gem 'thor-scmversion'

# Simple tasks
gem 'rake'

# Give me simple cli colors
gem 'colored'

# notification webhooks
gem 'httparty'

group :development do
  gem 'guard'
  gem 'guard-kitchen'
  gem 'guard-foodcritic'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'knife-cookbook-doc'
  gem 'knife-solo'
  gem 'knife-solo_data_bag'
  gem 'guard-shell'
end

# Allow for kitchen integration
group :integration do
  gem 'test-kitchen'
  gem 'kitchen-vagrant'
end

group :test do
  gem 'chef', '11.10'
  gem 'rspec', '~> 3.1'
end
