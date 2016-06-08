# frozen_string_literal: true

module ERBLint
  # Contains the logic for generating the file tree structure used by linters.
  module Parser
    END_MARKER_NAME = 'erb_lint_end_marker'

    class << self
      def parse(file_content)
        require 'nokogiri'
        require 'htmlentities'

        file_content += "<#{END_MARKER_NAME}>"\
          'This is used to calculate the line number of the last line'\
          "</#{END_MARKER_NAME}>"

        file_content_with_erb_tags = file_content.gsub(/<%(.+?)%>/m) do |_match|
          "<erb>#{HTMLEntities.new.encode($1)}</erb>"
        end

        file_content_with_erb_tags = escape_erb_tags_in_strings(file_content_with_erb_tags)

        file_tree = Nokogiri::XML.fragment(file_content_with_erb_tags)
        validate_tree(file_tree)

        file_tree
      end

      def remove_escaped_erb_tags(string)
        string.gsub(/_erb_.*?_\/erb_/, '')
      end

      private

      def escape_erb_tags_in_strings(file_content)
        scanner = StringScanner.new(file_content)

        while scanner.skip_until(/'|"/)
          open_string_type = scanner.matched

          string_start = scanner.pos - 1
          if scanner.skip_until(/#{open_string_type}/).nil?
            raise ParsingError, 'Unclosed string found.'
          end
          string_end = scanner.pos - 1

          string_content = file_content.byteslice(string_start..string_end)

          string_content_with_erb_tags_escaped = string_content.gsub(/(<erb>|<\/erb>)/m) do |_match|
            case $1
            when '<erb>'
              '_erb_'
            when '</erb>'
              '_/erb_'
            end
          end

          file_content[string_start..string_end] = string_content_with_erb_tags_escaped
        end

        file_content
      end

      def validate_tree(file_tree)
        if file_tree.children.empty? || file_tree.children.last.name != END_MARKER_NAME
          raise ParsingError, 'File could not be successfully parsed. Ensure all tags are properly closed.'
        end
      end
    end

    class ParsingError < StandardError
    end
  end
end
