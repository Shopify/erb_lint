# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :source_range, :message, :context
    attr_writer :status

    def initialize(linter, source_range, message, context = nil, status = :uncorrected)
      unless source_range.is_a?(Parser::Source::Range)
        raise ArgumentError, "expected Parser::Source::Range for arg 2"
      end
      @linter = linter
      @source_range = source_range
      @message = message
      @context = context
      @status = status
    end

    def corrected
      @status == :corrected
    end
    alias_method :corrected?, :corrected

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "source_range=#{source_range.begin_pos}...#{source_range.end_pos} "\
        "message=#{message}>"
    end

    def to_h
      {
        linter: linter.class.simple_name,
        corrected: linter.class.support_autocorrect? && corrected?,
        source_range: "#{source_range.begin_pos}...#{source_range.end_pos}",
        start_line: source_range.start_line,
        start_column: source_range.start_column,
        last_line: source_range.last_line,
        length: source_range.length,
        message: message,
      }
    end

    def ==(other)
      other.class <= ERBLint::Offense &&
        other.linter == linter &&
        other.source_range == source_range &&
        other.message == message
    end

    def line_range
      Range.new(source_range.line, source_range.last_line)
    end
  end
end
