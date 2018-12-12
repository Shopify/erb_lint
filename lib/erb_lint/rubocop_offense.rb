# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class RubocopOffense < Offense
    RUBOCOP_MESSAGE_PATTERN = /\A(?<linter>\S+): (?<message>.+)\z/.freeze

    def to_h
      linter_name, msg = linter_and_message(message)
      super.merge(linter: linter_name, message: msg)
    end

    private

    def linter_and_message(message)
      match = message.match(RUBOCOP_MESSAGE_PATTERN)
      [match[:linter], match[:message]]
    end
  end
end
