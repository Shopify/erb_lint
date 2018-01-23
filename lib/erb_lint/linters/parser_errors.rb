# frozen_string_literal: true

module ERBLint
  module Linters
    class ParserErrors < Linter
      include LinterRegistry

      def offenses(processed_source)
        processed_source.parser.parser_errors.map do |error|
          Offense.new(
            self,
            processed_source.to_source_range(error.loc.start, error.loc.stop - 1),
            "#{error.message} (at #{error.loc.source})"
          )
        end
      end
    end
  end
end
