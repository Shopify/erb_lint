# frozen_string_literal: true

module ERBLint
  module Formatters
    class DefaultFormatter
      attr_reader :output, :autocorrect

      def initialize(options = {})
        options.assert_valid_keys(:format, :autocorrect, :out)
        @output = output_setup(options[:out])
        @autocorrect = options[:autocorrect]
      end

      def report(stats)
        stats.files.each do |offending_file|
          path = offending_file[:path]
          offenses = offending_file[:offenses]

          offenses.each do |offense|
            @output.write(<<~EOF)
              #{offense.message}#{autocorrect_result(offense)}
              In file: #{path}:#{offense.line_range.begin}

            EOF
          end
        end

        if stats.corrected.positive?
          if stats.remaining_errors.positive?
            @output.write(rainbow.wrap(
              "#{stats.corrected} error(s) corrected and #{stats.remaining_errors} error(s) remaining in ERB files"
            ).red)
          else
            @output.write(rainbow.wrap("#{stats.corrected} error(s) corrected in ERB files").green)
          end
        elsif stats.offense_count.positive?
          @output.write(rainbow.wrap("#{stats.offense_count} error(s) were found in ERB files").red)
        else
          @output.write(rainbow.wrap("No errors were found in ERB files").green)
        end
        flush_output
      end

      private

      def autocorrect_result(offense)
        if autocorrect
          "#{offense.message}#{offense.corrected ? rainbow.wrap(' (autocorrected)').green : rainbow.wrap(' (not autocorrected)').red}"
        end
      end

      def rainbow
        @rainbow ||= begin
          rain = Rainbow.new
          rain.enabled = !output.is_a?(File)
          rain
        end
      end

      def output_setup(output_path)
        if output_path
          dir_path = File.dirname(output_path)
          FileUtils.mkdir_p(dir_path) unless File.exist?(dir_path)
          File.open(output_path, 'w')
        else
          $stdout
        end
      end

      def flush_output
        output.write("\n")
        output.close if output.is_a?(File)
      end
    end
  end
end
