module ERBLint
  class Linter
    class CustomLinter < Linter
      include LinterRegistry
    end
  end
end