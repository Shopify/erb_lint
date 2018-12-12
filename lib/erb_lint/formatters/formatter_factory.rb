# frozen_string_literal: true

require 'erb_lint/formatters/default_formatter'
require 'erb_lint/formatters/json_formatter'

module ERBLint
  module Formatters
    # Factory class to get the desired formatter
    class FormatterFactory
      AVAILABLE_FORMATTERS = {
        default: DefaultFormatter,
        json: JSONFormatter,
      }
      def self.build(options = {})
        options.symbolize_keys!
        options.assert_valid_keys(:format, :autocorrect, :output)
        format = (options[:format] || :default).to_sym
        (AVAILABLE_FORMATTERS[format] || DefaultFormatter).new(options.slice(:autocorrect, :output))
      end
    end
  end
end
