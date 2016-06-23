# frozen_string_literal: true
require 'nokogiri'
require 'htmlentities'

module ERBLint
  # Contains the logic for generating the file tree structure used by linters.
  module Parser
    END_MARKER_NAME = 'erb_lint_end_marker'

    class << self
      def parse(file_content)
        clean_file_content = strip_erb_tags(file_content)

        xml_ready_file_content = add_end_marker(clean_file_content)

        file_tree = Nokogiri::XML.fragment(xml_ready_file_content)

        ensure_valid_tree(file_tree)

        file_tree
      end

      def file_is_empty?(file_tree)
        top_level_elements = file_tree.children
        top_level_elements.size == 1 && top_level_elements.last.name == END_MARKER_NAME
      end

      private

      def strip_erb_tags(file_content)
        scanner = StringScanner.new(file_content)

        while scanner.skip_until(/<%/)
          start_tag_index = scanner.pos - 2

          is_start_tag_literal = scanner.peek(1) == '%'
          if is_start_tag_literal
            scanner.pos += 1
            next
          end

          end_tag_index = find_end_tag_index(file: file_content, scanner: scanner)

          file_content = remove_tag(file: file_content, start_index: start_tag_index, end_index: end_tag_index)
        end

        file_content = escape_erb_tag_literals(file_content)

        file_content
      end

      def find_end_tag_index(file:, scanner:)
        end_tag_not_found = true

        while end_tag_not_found
          raise ParseError, 'Unclosed ERB tag found.' if scanner.skip_until(/%>/).nil?
          is_end_tag_literal = file[scanner.pos - 3] == '%'
          end_tag_not_found = false unless is_end_tag_literal
        end

        scanner.pos - 1
      end

      def remove_tag(file:, start_index:, end_index:)
        erb_tag = file.byteslice(start_index..end_index)

        whitespace_filler = erb_tag.gsub(/[^\n]/, ' ')

        file_copy = file.dup
        file_copy[start_index..end_index] = whitespace_filler
        file_copy
      end

      def escape_erb_tag_literals(file_content)
        file_content.gsub(/(<%%|%%>)/) do |tag_literal|
          HTMLEntities.new.encode(tag_literal)
        end
      end

      def add_end_marker(file_content)
        file_content + <<~END_MARKER.chomp
          <#{END_MARKER_NAME}>
            This is used to calculate the line number of the last line.
            This is only necessary until Text#line is fixed in Nokogiri.
          </#{END_MARKER_NAME}>
        END_MARKER
      end

      def ensure_valid_tree(file_tree)
        if file_tree.children.empty? || file_tree.children.last.name != END_MARKER_NAME
          raise ParseError, 'File could not be successfully parsed. Ensure all tags are properly closed.'
        end
      end
    end

    class ParseError < StandardError
    end
  end
end
