# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :source_range, :message

    def initialize(linter, source_range, message)
      unless source_range.is_a?(Parser::Source::Range)
        raise ArgumentError, "expected Parser::Source::Range for arg 2"
      end
      @linter = linter
      @source_range = source_range
      @message = message
    end

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "source_range=#{source_range.begin_pos}..#{source_range.end_pos - 1} "\
        "message=#{message}>"
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
