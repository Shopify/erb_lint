# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for final newlines at the end of a file.
    class FinalNewline < Linter
      include LinterRegistry

      def initialize(config)
        @new_lines_should_be_present = config['present'].nil? ? true : config['present']
      end

      def lint_file(file_tree, _ruby_ast)
        return [] if HTMLParser.file_is_empty?(file_tree)

        end_marker = file_tree.search(HTMLParser::END_MARKER_NAME).first
        last_child = end_marker.previous_sibling

        generate_errors(last_element: last_child, end_marker_line_number: end_marker.line)
      end

      private

      def generate_errors(last_element:, end_marker_line_number:)
        if ends_with_newline?(last_element) && !@new_lines_should_be_present
          message = 'Remove the trailing newline at the end of the file.'
          last_line = end_marker_line_number - 1
        elsif !ends_with_newline?(last_element) && @new_lines_should_be_present
          message = 'Missing a trailing newline at the end of the file.'
          last_line = end_marker_line_number
        else
          return []
        end

        [{ message: message, line: last_line }]
      end

      def ends_with_newline?(node)
        node.text? && node.text.chars[-1] == "\n"
      end
    end
  end
end
