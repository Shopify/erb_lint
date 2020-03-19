# frozen_string_literal: true

module ERBLint
  module Reporters
    class CompactReporter < Reporter
      def show
        files.each do |filename, offenses|
          offenses.each do |offense|
            puts format_offense(filename, offense)
          end
        end

        report_summary
      end

      private

      def format_offense(filename, offense)
        [
          "#{filename}:",
          "#{offense.line_number}:",
          "#{offense.column}: ",
          offense.message.to_s,
        ].join
      end

      def report_summary
        if stats.corrected > 0
          report_corrected_offenses
        elsif stats.found > 0
          warn(Rainbow("#{stats.found} error(s) were found in ERB files").red)
        else
          puts Rainbow("No errors were found in ERB files").green
        end
      end

      def report_corrected_offenses
        corrected_found_diff = stats.found - stats.corrected

        if corrected_found_diff > 0
          message = Rainbow(
            "#{stats.corrected} error(s) corrected and #{corrected_found_diff} error(s) remaining in ERB files"
          ).red

          warn(message)
        else
          puts Rainbow("#{stats.corrected} error(s) corrected in ERB files").green
        end
      end
    end
  end
end
