require 'erubis'
require 'parser/current'

RubyParser = Parser

module ERBLint
  module ERBParser

    class << self
      def parse(file_content)
        eruby = Erubis::Eruby.new(file_content)

        ast = RubyParser::CurrentRuby.parse(eruby.src)

        ast
      end
    end
  end
end
