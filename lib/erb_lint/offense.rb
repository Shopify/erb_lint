# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :source_range, :message, :context, :severity

    def initialize(linter, source_range, message, context = nil, severity = nil)
      unless source_range.is_a?(Parser::Source::Range)
        raise ArgumentError, "expected Parser::Source::Range for arg 2"
      end

      @linter = linter
      @source_range = source_range
      @message = message
      @context = context
      @severity = severity
    end

    def to_json_format
      {
        linter_config: linter.config.to_hash,
        source_range: source_range_to_json_format,
        message: message,
        context: context,
        severity: severity,
      }
    end

    def source_range_to_json_format
      {
        begin_pos: source_range.begin_pos,
        end_pos: source_range.end_pos,
        source_buffer_source: source_range.source_buffer.source,
        source_buffer_name: source_range.source_buffer.name,
      }
    end

    def self.from_json(parsed_json, file_loader, config)
      parsed_json.transform_keys!(&:to_sym)
      linter_config = ERBLint::LinterConfig.new(parsed_json[:linter_config])
      new(
        linter_config,
        source_range_from_json_format(parsed_json[:source_range]),
        parsed_json[:message].presence,
        parsed_json[:context].presence,
        parsed_json[:severity].presence
      )
    end

    def self.source_range_from_json_format(parsed_json_source_range)
      parsed_json_source_range.transform_keys!(&:to_sym)
      Parser::Source::Range.new(
        Parser::Source::Buffer.new(
          parsed_json_source_range[:source_buffer_name],
          source: parsed_json_source_range[:source_buffer_source]
        ),
        parsed_json_source_range[:begin_pos],
        parsed_json_source_range[:end_pos]
      )
    end

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "source_range=#{source_range.begin_pos}...#{source_range.end_pos} "\
        "message=#{message}> "\
        "severity=#{severity}"
    end

    def ==(other)
      other.class <= ERBLint::Offense &&
        other.linter == linter &&
        other.source_range == source_range &&
        other.message == message &&
        other.severity == severity
    end

    def line_range
      Range.new(source_range.line, source_range.last_line)
    end

    def line_number
      line_range.begin
    end

    def column
      source_range.column
    end
  end
end
