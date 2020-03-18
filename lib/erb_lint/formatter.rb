# frozen_string_literal: true

module ERBLint
  class Formatter
    def initialize(offenses, filename, autocorrect)
      @offenses = offenses
      @filename = filename
      @autocorrect = autocorrect
    end

    def format
      offenses.map { |offense| format_offense(offense) }
    end

    private

    attr_reader :offenses, :filename, :autocorrect
  end
end
