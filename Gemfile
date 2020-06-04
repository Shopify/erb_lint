# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport', '~> 5.1'
gem 'rake'

group 'test' do
  gem 'fakefs'
end

gemspec

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile local_gemfile if File.exist?(local_gemfile)
