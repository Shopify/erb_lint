# frozen_string_literal: true

require 'erb_lint'
require 'rainbow'

module ERBLint
  module Formatters
    class DefaultFormatter
      def initialize
        @results = {}
      end

      def file_completed(filename, runner)
        @results[filename] = runner
      end

      def report(stats, options, io = STDOUT)
        @results.each do |filename, runner|
          runner.offenses.each do |offense|
            io.puts <<~EOF
              #{offense.message}#{Rainbow(' (not autocorrected)').red if options[:autocorrect]}
              In file: #{relative_filename(filename)}:#{offense.line_range.begin}

            EOF
          end
        end

        if stats.corrected > 0
          corrected_found_diff = stats.found - stats.corrected
          if corrected_found_diff > 0
            warn Rainbow(
              "#{stats.corrected} error(s) corrected and #{corrected_found_diff} error(s) remaining in ERB files"
            ).red
          else
            io.puts Rainbow("#{stats.corrected} error(s) corrected in ERB files").green
          end
        elsif stats.found > 0
          warn Rainbow("#{stats.found} error(s) were found in ERB files").red
        else
          io.puts Rainbow("No errors were found in ERB files").green
        end
      end

      private

      def relative_filename(filename)
        filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
      end
    end
  end
end
