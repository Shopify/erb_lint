# frozen_string_literal: true

module ERBLint
  class ProcessedSource
    attr_reader :file_content, :parser

    def initialize(file_content)
      @file_content = file_content
      @parser = BetterHtml::Parser.new(file_content, template_language: :html)
    end

    def ast
      @parser.ast
    end
  end
end
