# frozen_string_literal: true

require 'better_html'
require 'better_html/test_helper/safe_erb_tester'

module ERBLint
  module Linters
    # Detect unsafe ruby interpolations into javascript.
    class ErbSafety < Linter
      include LinterRegistry
      include BetterHtml::TestHelper::SafeErbTester

      def initialize(file_loader, config)
        super
        @config_filename = config['better-html-config']
      end

      def lint_file(file_content)
        errors = []
        tester = Tester.new(file_content, config: better_html_config)
        tester.errors.each do |error|
          errors << format_error(error)
        end
        errors
      end

      private

      def better_html_config
        @better_html_config ||= begin
          config_hash =
            if @config_filename.nil?
              {}
            else
              @file_loader.yaml(@config_filename)
            end
          BetterHtml::Config.new(**config_hash)
        end
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
