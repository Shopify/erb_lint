# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for instance variables in partials.
    class InstanceVariable < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :partials_only, accepts: [true, false], default: true, reader: :partials_only?
      end
      self.config_schema = ConfigSchema

      INSTANCE_VARIABLE_REGEX = /[^@]?(@?@[a-z_][a-zA-Z_0-9]*)/.freeze
      PARTIAL_FILE_REGEX = %r{(\A|.*/)_[^/\s]*\.html\.erb\z}.freeze

      def run(processed_source)
        return unless process_file?(processed_source)

        matches = processed_source
          .file_content
          .to_enum(:scan, INSTANCE_VARIABLE_REGEX)
          .map { Regexp.last_match }
        return if matches.empty?

        matches.each do |match|
          range = match.begin(1)...match.end(1)
          add_offense(processed_source.to_source_range(range), offense_message)
        end
      end

      private

      def process_file?(processed_source)
        return true unless @config.partials_only?

        processed_source.filename.match?(PARTIAL_FILE_REGEX)
      end

      def offense_message
        "Instance variable detected."
      end
    end
  end
end
