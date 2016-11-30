# frozen_string_literal: true

require 'erb_lint/linter_registry'
require 'erb_lint/linter'
require 'erb_lint/html_parser'
require 'erb_lint/runner'

# Load linters
Dir[File.expand_path('erb_lint/linters/**/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
