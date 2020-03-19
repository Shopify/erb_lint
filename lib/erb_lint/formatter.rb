# frozen_string_literal: true
require 'active_support/core_ext/class'

module ERBLint
  class Formatter
    delegate :files, to: :stats

    def initialize(stats, autocorrect)
      @autocorrect = autocorrect
      @stats = stats
    end

    def format; end

    private

    attr_reader :stats, :autocorrect
  end
end
