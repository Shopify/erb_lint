# frozen_string_literal: true

module ERBLint
  module Formatters
    class CompactFormatter < Formatter
      private

      def format_offense(offense)
        [
          "#{filename}:",
          "#{offense.line_number}:",
          "#{offense.column}: ",
          offense.message.to_s,
        ].join
      end
    end
  end
end
