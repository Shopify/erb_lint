# frozen_string_literal: true

module ERBLint
  class Formatter
    def self.inherited(klass)
      @descendants ||= []
      @descendants << klass
    end

    def self.descendants
      @descendants || []
    end

    def initialize(filename, autocorrect)
      @filename = filename
      @autocorrect = autocorrect
    end

    def format(offenses)
      offenses.map { |offense| format_offense(offense) }
    end

    private

    attr_reader :filename, :autocorrect
  end
end
