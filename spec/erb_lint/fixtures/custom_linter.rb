# frozen_string_literal: true

module ERBLint
  class Linter
    class CustomLinter < Linter
      include LinterRegistry
    end
  end
end
