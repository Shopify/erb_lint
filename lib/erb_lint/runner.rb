module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    attr_reader :lints

    def initialize(config)
      LinterRegistry.load_linters
      @linters = LinterRegistry.linters.select { |linter| linter_enabled?(config, linter) }
    end

    def run(file)
      @linters.map do |linter|
        {
          linter: linter
          errors: linter.lint(file)
        }
      end
    end

    private

    def linter_enabled?(config, linter)
      linters = config['linters']
      linter_found = linters[linter.name]
      return false if linter_found.nil?
      linter_found['enabled'] || false
    end
  end
end
