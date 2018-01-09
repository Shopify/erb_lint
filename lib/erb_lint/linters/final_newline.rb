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

      protected

      def lint_lines(lines)
        errors = []
        return errors if lines.empty?

        ends_with_newline = lines.last.chars[-1] == "\n"

        if @new_lines_should_be_present && !ends_with_newline
          errors << Offense.new(
            self,
            Range.new(lines.length, lines.length),
            'Missing a trailing newline at the end of the file.'
          )
        elsif !@new_lines_should_be_present && ends_with_newline
          errors << Offense.new(
            self,
            Range.new(lines.length, lines.length),
            'Remove the trailing newline at the end of the file.'
          )
        end
        errors
      end
    end
  end
end
