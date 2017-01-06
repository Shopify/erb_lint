require 'erubi/capture'
require 'parser/current'

module ERBLint
  module ERBParser
    class << self
      def parse(file_content)
        file_content = transform_capture_blocks(file_content)
        eruby = Erubi::CaptureEngine.new(file_content)
        Parser::CurrentRuby.parse(eruby.src)
      rescue Parser::SyntaxError
        raise ParseError, 'File could not be parsed.'
      end

      private

      def transform_capture_blocks(src)
        regexp = /<%(={1,2}(?:(?!%>)[\s\S])+(?:\sdo\s(?:\|.*\|\s)?){1}%>)/
        src.gsub(regexp) { "<%|#{$1}" }
      end
    end

    class ParseError < StandardError
    end
  end
end
