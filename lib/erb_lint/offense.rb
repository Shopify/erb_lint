# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :line_range, :message

    def initialize(linter, line_range, message)
      @linter = linter
      @line_range = line_range
      @message = message
    end

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "line_range=#{line_range} "\
        "message=#{message}>"
    end

    def ==(other)
      other.class == self.class &&
        other.linter == linter &&
        other.line_range == line_range &&
        other.message == message
    end
  end
end
