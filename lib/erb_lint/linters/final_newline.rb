# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for final newlines at the end of a file.
    class FinalNewline < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :present, accepts: [true, false], default: true, reader: :present?
      end
      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        super
        @new_lines_should_be_present = @config.present?
      end

      def offenses(processed_source)
        file_content = processed_source.file_content

        offenses = []
        return offenses if file_content.empty?

        match = file_content.match(/(\n+)\z/)
        ends_with_newline = match.present?

        if @new_lines_should_be_present && !ends_with_newline
          offenses << Offense.new(
            self,
            processed_source.to_source_range(file_content.size, file_content.size - 1),
            'Missing a trailing newline at the end of the file.'
          )
        elsif !@new_lines_should_be_present && ends_with_newline
          offenses << Offense.new(
            self,
            processed_source.to_source_range(match.begin(0), match.end(0) - 1),
            "Remove #{match[0].size} trailing newline at the end of the file."
          )
        end
        offenses
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          if @new_lines_should_be_present
            corrector.insert_after(offense.source_range, "\n")
          else
            corrector.remove_trailing(offense.source_range, offense.source_range.size)
          end
        end
      end
    end
  end
end
