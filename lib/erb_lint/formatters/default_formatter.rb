# frozen_string_literal: true

module ERBLint
  module Formatters
    class DefaultFormatter
      def initialize
        @results = {}
      end

      def file_completed(relative_filename, runner)
        @results[relative_filename] = runner
      end

      def report(stats, options, io)
        @results.each do |relative_filename, runner|
          runner.offenses.each do |offense|
            io.puts <<~EOF
              #{offense.message}#{Rainbow(' (not autocorrected)').red if options[:autocorrect]}
              In file: #{relative_filename}:#{offense.line_range.begin}

            EOF
          end
        end

        if stats.corrected > 0
          corrected_found_diff = stats.found - stats.corrected
          if corrected_found_diff > 0
            io.puts Rainbow(
              "#{stats.corrected} error(s) corrected and #{corrected_found_diff} error(s) remaining in ERB files"
            ).red
          else
            io.puts Rainbow("#{stats.corrected} error(s) corrected in ERB files").green
          end
        elsif stats.found > 0
          io.puts Rainbow("#{stats.found} error(s) were found in ERB files").red
        else
          io.puts Rainbow("No errors were found in ERB files").green
        end
      end
    end
  end
end
