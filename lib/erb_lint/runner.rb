module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    attr_reader :lints

    def initialize(config)
      @config = config
      LinterRegistry.load_linters
      @linters = LinterRegistry.linters.select { |linter| linter_enabled?(linter) }
    end

    def run(file)
      @linters.map do |linter|
        {
          linter: linter,
          errors: linter.lint(file)
        }
      end
    end

    private

    def linter_enabled?(linter)
      linters = @config['linters']
      linter_found = linters[linter.simple_name]
      return false if linter_found.nil?
      linter_found['enabled'] || false
    end
  end
end
