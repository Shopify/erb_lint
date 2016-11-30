# frozen_string_literal: true
require 'nokogiri'
require 'htmlentities'
require 'securerandom'

module ERBLint
  # Contains the logic for generating the file tree structure used by linters.
  module HTMLParser
    END_MARKER_NAME = 'erb_lint_end_marker'

    class << self
      def parse(file_content)
        seed = SecureRandom.hex(10)
        html_ready_file_content = escape_erb_tags(file_content, seed)

        final_file_content = add_end_marker(html_ready_file_content)

        file_tree = Nokogiri::HTML.fragment(final_file_content)

        restore_erb_tags(file_tree, seed)

        ensure_valid_tree(file_tree)

        file_tree
      end

      def file_is_empty?(file_tree)
        top_level_elements = file_tree.children
        top_level_elements.size == 1 && top_level_elements.last.name == END_MARKER_NAME
      end

      def get_all_nodes(nodes)
        nodes.search('.//node()')
      end

      def get_non_text_nodes(nodes)
        nodes.search('*')
      end

      def get_text_nodes(nodes)
        nodes.search('.//text()')
      end

      def get_attributes(nodes)
        nodes.search('.//@*')
      end

      private

      def escape_erb_tags(file_content, seed)
        scanner = StringScanner.new(file_content)

        while scanner.skip_until(/<%/)
          start_tag_index = scanner.pos - 2

          is_start_tag_literal = scanner.peek(1) == '%'
          if is_start_tag_literal
            scanner.pos += 1
            next
          end

          end_tag_index = find_end_tag_index(file: file_content, scanner: scanner)

          file_content, new_scanner_pos = escape_tag(
            file: file_content,
            start_index: start_tag_index,
            end_index: end_tag_index,
            escape_seed: seed
          )

          scanner = StringScanner.new(file_content)
          scanner.pos = new_scanner_pos
        end
        file_content_encoded_erb_tag_literals(file_content)
      end

      def file_content_encoded_erb_tag_literals(file_content)
        file_content = encode_erb_tag_literals(file_content)
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

      def escape_tag(file:, start_index:, end_index:, escape_seed:)
        bare_erb_tag = file.byteslice(start_index..end_index)

        escaped_tag = bare_erb_tag
                      .gsub(/<%/, "_erb#{escape_seed}start_")
                      .gsub(/%>/, "_erb#{escape_seed}end_")
        escaped_encoded_tag = HTMLEntities.new.encode(escaped_tag)

        file = replace_tag_in_file(
          file: file,
          start_index: start_index,
          end_index: end_index,
          content: escaped_encoded_tag
        )

        new_end_index = start_index + escaped_tag.length

        [file, new_end_index]
      end

      def replace_tag_in_file(file:, start_index:, end_index:, content:)
        left_boundary = start_index - 1
        preceding_content = left_boundary.negative? ? '' : file[0..left_boundary]

        right_boundary = end_index + 1
        following_content = right_boundary > file.length - 1 ? '' : file[right_boundary..-1]

        preceding_content + content + following_content
      end

      def encode_erb_tag_literals(file_content)
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

      def restore_erb_tags(file_tree, seed)
        text_containers = get_text_nodes(file_tree) + get_attributes(file_tree)
        text_containers.each do |text_container|
          erb_tag_restored_content = text_container.content
                                                   .gsub(/_erb#{seed}start_/, '<%')
                                                   .gsub(/_erb#{seed}end_/, '%>')
          text_container.content = erb_tag_restored_content
        end

        # in the future we would ideally parse out the erb tags into real nodes and assign line numbers
      end

      # Temporarily suppressing invalid HTML errors because nokogiri is raising lots of false positives
      def ensure_valid_tree(_file_tree)
        true
      end
    end

    class ParseError < StandardError
    end
  end
end
