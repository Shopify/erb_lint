module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    attr_reader :lints

    def initialize(config)
      @config = config
      LinterRegistry.load_linters
      @linters = LinterRegistry.linters.select { |linter| linter_enabled?(linter) }
      @linters.map! do |linter_class|
        linter_config = @config['linters'][linter_class.simple_name]
        linter_class.new(linter_config)
      end
    end

    def run(file)
      @linters.map do |linter|
        {
          linter: linter.class,
          errors: linter.lint_file(file)
        }
      end
    end

    private

    def linter_enabled?(linter_class)
      linter_classes = @config['linters']
      linter_class_found = linter_classes[linter_class.simple_name]
      return false if linter_class_found.nil?
      linter_class_found['enabled'] || false
    end
  end
end
