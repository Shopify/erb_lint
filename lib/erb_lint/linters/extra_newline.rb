# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects multiple blank lines
    class ExtraNewline < Linter
      include LinterRegistry

      EXTRA_NEWLINES = /(\n{3,})/m

      def offenses(processed_source)
        matches = processed_source.file_content.match(EXTRA_NEWLINES)
        return [] unless matches

        offenses = []
        matches.captures.each_index do |index|
          offenses << Offense.new(
            self,
            processed_source.to_source_range(
              matches.begin(index) + 2,
              matches.end(index) - 1
            ),
            "Extra blank line detected."
          )
        end
        offenses
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, '')
        end
      end
    end
  end
end
