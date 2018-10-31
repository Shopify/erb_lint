# frozen_string_literal: true

module ERBLint
  module Formatters
    class JSONFormatter
      RUBOCOP_MESSAGE_PATTERN = /\A(?<linter>\S+): (?<message>.+)\z/.freeze

      def initialize
        @result = {
          metadata: metadata_hash,
          files: [],
          summary: {offense_count: 0, inspected_file_count: 0}
        }
      end

      def file_completed(relative_filename, runner)
        @result[:summary][:offense_count] += runner.offenses.count
        @result[:summary][:inspected_file_count] += 1
        @result[:files] = hash_for_file(relative_filename, runner)
      end

      def report(stats, options, io)
        io.puts JSON.pretty_generate(@result)
      end

      private

      def metadata_hash
        {
          erb_lint_version: ERBLint::VERSION,
          ruby_engine: RUBY_ENGINE,
          ruby_version: RUBY_VERSION,
          ruby_patchlevel: RUBY_PATCHLEVEL.to_s,
          ruby_platform: RUBY_PLATFORM
        }
      end

      def hash_for_file(relative_filename, runner)
        {
          path: relative_filename,
          offenses: runner.offenses.map { |o| hash_for_offense(o) }
        }
      end

      def hash_for_offense(offense)
        linter, message = linter_and_message(offense)
        {
          message: message,
          linter: linter,
          corrected: offense_corrected?(offense),
          location: hash_for_location(offense)
        }
      end

      def linter_and_message(offense)
        if offense.linter.is_a?(ERBLint::Linters::Rubocop)
          rubocop_linter_and_message offense.message
        else
          [offense.linter.class.simple_name, offense.message]
        end
      end

      def offense_corrected?(offense)
        offense.context.is_a?(Hash) && offense.context.key?(:rubocop_correction)
      end

      def rubocop_linter_and_message(message)
        match = message.match(RUBOCOP_MESSAGE_PATTERN)
        [match[:linter], match[:message]]
      end

      def hash_for_location(offense)
        {
          start_line: offense.source_range.start_line,
          start_column: offense.source_range.start_column,
          last_line: offense.source_range.last_line,
          length: offense.source_range.length
        }
      end
    end
  end
end
