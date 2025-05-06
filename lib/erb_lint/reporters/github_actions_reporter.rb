# frozen_string_literal: true

module ERBLint
  module Reporters
    class GithubActionsReporter < ERBLint::Reporter
      ESCAPE_MAP = { "%" => "%25", "\n" => "%0A", "\r" => "%0D" }.freeze

      def preview; end

      def show
        puts formatted_data
      end

      private

      def formatted_data
        formatted_files.join("\n")
      end

      def formatted_files
        processed_files.flat_map do |filename, offenses|
          offenses.map do |offense|
            format_offense(filename, offense)
          end
        end
      end

      def format_offense(filename, offense)
        message = github_escape("#{offense.simple_name}: #{offense.message}")
        severity = github_severity(offense)

        "::#{severity} file=#{filename},line=#{offense.line_number},col=#{offense.column}::#{message}"
      end

      def github_escape(string)
        string.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
      end

      def github_severity(offense)
        [nil, :error, :fatal].include?(offense.severity) ? "warning" : "error"
      end
    end
  end
end
