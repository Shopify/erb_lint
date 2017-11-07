# frozen_string_literal: true

require 'better_html'
require 'better_html/test_helper/safe_erb_tester'

module ERBLint
  module Linters
    # Detect unsafe ruby interpolations into javascript.
    class ErbSafety < Linter
      include LinterRegistry
      include BetterHtml::TestHelper::SafeErbTester

      def initialize(config)
      end

      def lint_file(file_content)
        errors = []
        tester = Tester.new(file_content)
        tester.errors.each do |error|
          errors << format_error(error)
        end
        errors
      end

      private

      def config
        BetterHtml::Config.new(
          **YAML.load(File.read(Rails.root.join('config/better-html.yml'))).symbolize_keys
        )
      end

      def format_error(error)
        {
          line: error.location.line,
          message: error.message
        }
      end
    end
  end
end
