# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for final newlines at the end of a file.
    class FinalNewline < Linter
      include LinterRegistry

      def initialize(config)
        @new_lines_should_be_present = config['present'].nil? ? true : config['present']
      end

      def lint_file(file_tree)
        errors = []
        return errors if file_tree.children.size == 1

        end_marker = file_tree.search(Parser::END_MARKER_NAME).first
        last_child = end_marker.previous_sibling
        ends_with_newline = last_child.text? && last_child.text.chars[-1] == "\n"

        if @new_lines_should_be_present && !ends_with_newline
          errors.push(
            line: end_marker.line,
            message: 'Missing a trailing newline at the end of the file.'
          )
        elsif !@new_lines_should_be_present && ends_with_newline
          errors.push(
            line: end_marker.line - 1,
            message: 'Remove the trailing newline at the end of the file.'
          )
        end
        errors
      end
    end
  end
end
