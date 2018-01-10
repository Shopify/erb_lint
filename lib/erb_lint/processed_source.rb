# frozen_string_literal: true

module ERBLint
  class ProcessedSource
    attr_reader :filename, :file_content, :parser

    def initialize(filename, file_content)
      @filename = filename
      @file_content = file_content
      @parser = BetterHtml::Parser.new(file_content, template_language: :html)
    end

    def ast
      @parser.ast
    end

    def source_buffer
      @source_buffer ||= begin
        buffer = Parser::Source::Buffer.new(filename)
        buffer.source = file_content
        buffer
      end
    end

    def to_source_range(begin_pos, end_pos)
      Parser::Source::Range.new(source_buffer, begin_pos, end_pos + 1)
    end
  end
end
