# frozen_string_literal: true

module ERBLint
  class ProcessedSource
    attr_reader :filename, :file_content, :parser

    def initialize(filename, file_content)
      @filename = filename
      @file_content = file_content
      @parser = build_parser
    end

    def ast
      @parser.ast
    end

    def source_buffer
      @source_buffer ||= begin
        buffer = ParserSourceBuffer.new(filename)
        buffer.source = file_content
        buffer
      end
    end

    def to_source_range(range)
      range = (range.begin_pos...range.end_pos) if range.is_a?(::Parser::Source::Range)
      BetterHtml::Tokenizer::Location.new(
        source_buffer,
        range.begin,
        range.exclude_end? ? range.end : range.end + 1,
      )
    end

    private

    def build_parser
      source = source_buffer.source
      parser_source = source.dup

      loop do
        parser = source_buffer.with_parser_source(parser_source) do
          BetterHtml::Parser.new(source_buffer, template_language: :html)
        end
        candidate_positions = parser.parser_errors.filter_map do |error|
          position = error.loc.begin_pos
          less_than_position = position - 1
          next_character_position = position
          next_character_position += 1 while parser_source[next_character_position]&.match?(/\s/)
          next_character = parser_source[next_character_position]

          next unless position.positive? &&
            parser_source[less_than_position] == "<" &&
            parser_source[position]&.match?(/\s/)
          next if next_character.nil? || next_character.match?(/[a-z]/i) || ["/", ">"].include?(next_character)

          less_than_position
        end
        return parser if candidate_positions.empty?

        malformed_tag_positions = parser.nodes_with_type(:tag).filter_map do |tag_node|
          if BetterHtml::Tree::Tag.from_node(tag_node).name.nil?
            tag_node.loc.begin_pos
          end
        end
        less_than_positions = candidate_positions & malformed_tag_positions
        return parser if less_than_positions.empty?

        # BetterHtml treats a less-than sign followed by whitespace as a malformed tag.
        # Only retry when the next non-whitespace character cannot begin a tag; this
        # preserves diagnostics for tags with whitespace before their name. Replace the
        # sign with a same-width placeholder while tokenizing, then expose the original
        # source to all ranges. Iterate because retrying can expose further literal
        # less-than signs that the initial parse consumed as part of one malformed tag.
        changed = false
        less_than_positions.uniq.each do |position|
          next unless parser_source[position] == "<"

          parser_source[position] = " "
          changed = true
        end
        return parser unless changed
      end
    end

    class ParserSourceBuffer < Parser::Source::Buffer
      def with_parser_source(parser_source)
        @parser_source = parser_source
        yield
      ensure
        @parser_source = nil
      end

      def source
        @parser_source || super
      end
    end
  end
end
