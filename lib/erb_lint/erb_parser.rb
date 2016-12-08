require 'erubis'
require 'parser/current'

module ERBLint
  module ERBParser
    def parse(file_content)
      eruby = Erubis::Eruby.new(file_content)
      Parser::CurrentRuby.parse(eruby.src)
    rescue Erubis::ErubisError, Parser::SyntaxError
      raise ParseError, 'File is not valid ERB and could not be parsed.'
    end

    class ParseError < StandardError
    end
  end
end
