# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects trailing whitespace at the end of a line
    class ExtraNewline < Linter
      include LinterRegistry

      def offenses(processed_source)
        lines = processed_source.file_content.split("\n", -1)
        document_pos = 0
        offenses = []
        lines.each_with_index do |line, index|
          break if index >= lines.count - 1
          document_pos += line.length + 1
          next unless line.empty? && lines[index + 1].empty?

          offenses << Offense.new(
            self,
            processed_source.to_source_range(document_pos, document_pos),
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
