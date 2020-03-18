# frozen_string_literal: true

module ERBLint
  module Formatters
    class MultilineFormatter < Formatter
      private

      def format_offense(offense)
        <<~EOF
          #{offense.message}#{Rainbow(' (not autocorrected)').red if autocorrect}
          In file: #{filename}:#{offense.line_number}

        EOF
      end
    end
  end
end
