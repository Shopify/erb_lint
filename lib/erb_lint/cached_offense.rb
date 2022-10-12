# frozen_string_literal: true

module ERBLint
  # A Cached version of an Offense with only essential information represented as strings
  class CachedOffense
    attr_reader :line_number, :message, :severity

    def initialize(message, line_number, severity)
      @message = message
      @line_number = line_number
      @severity = severity
    end

    def self.new_from_offense(offense)
      new(
        offense.message,
        offense.line_number.to_s,
        offense.severity
      )
    end

    def to_json_format
      {
        message: message,
        line_number: line_number,
        severity: severity,
      }
    end

    def self.from_json(parsed_json)
      parsed_json.transform_keys!(&:to_sym)
      new(
        parsed_json[:message],
        parsed_json[:line_number],
        parsed_json[:severity]&.to_sym
      )
    end
  end
end
