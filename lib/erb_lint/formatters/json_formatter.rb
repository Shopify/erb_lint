# frozen_string_literal: true

module ERBLint
  module Formatters
    # JSON results formatter class
    class JSONFormatter < DefaultFormatter
      def initialize(options = {})
        super(options)
      end

      def report(stats)
        @output.write(JSON.pretty_generate(stats))
        flush_output
      end
    end
  end
end
