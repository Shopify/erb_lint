# frozen_string_literal: true

require 'better_html'
require 'better_html/test_helper/safe_erb_tester'

module ERBLint
  module Linters
    # Detect unsafe ruby interpolations into javascript.
    class ErbSafety < Linter
      include LinterRegistry
      include BetterHtml::TestHelper::SafeErbTester

      class ConfigSchema < LinterConfig
        property :better_html_config, accepts: String
      end

      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        super
        @config_filename = @config.better_html_config
      end

      def offenses(processed_source)
        offenses = []
        tester = Tester.new(processed_source.file_content, config: better_html_config)
        tester.errors.each do |error|
          offenses << Offense.new(
            self,
            processed_source.to_source_range(error.location.start, error.location.stop),
            error.message
          )
        end
        offenses
      end

      private

      def better_html_config
        @better_html_config ||= begin
          config_hash =
            if @config_filename.nil?
              {}
            else
              @file_loader.yaml(@config_filename).symbolize_keys
            end
          BetterHtml::Config.new(**config_hash)
        end
      end
    end
  end
end
