# frozen_string_literal: true

require 'erb_lint/cli/errors/exit_with_failure'
require 'erb_lint/cli/errors/exit_with_success'
require 'erb_lint/cli/opt_parser'
require 'erb_lint/config_loader'
require 'erb_lint/corrector'
require 'erb_lint/file_loader'
require 'erb_lint/formatters/formatter_factory'
require 'erb_lint/formatters/default_formatter'
require 'erb_lint/formatters/json_formatter'
require 'erb_lint/linter_config'
require 'erb_lint/linter_registry'
require 'erb_lint/linter'
require 'erb_lint/offense'
require 'erb_lint/processed_source'
require 'erb_lint/runner_config'
require 'erb_lint/runner'
require 'erb_lint/stats'
require 'erb_lint/utils/file_utils'
require 'erb_lint/version'

# Load linters
Dir[File.expand_path('erb_lint/linters/**/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
