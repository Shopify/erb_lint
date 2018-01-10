# frozen_string_literal: true

module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    def initialize(file_loader, config)
      @file_loader = file_loader
      @config = config || RunnerConfig.default
      raise ArgumentError, 'expect `config` to be a RunnerConfig instance' unless @config.is_a?(RunnerConfig)

      LinterRegistry.load_custom_linters
      linter_classes = LinterRegistry.linters.select { |klass| @config.for_linter(klass).enabled? }
      @linters = linter_classes.map do |linter_class|
        linter_class.new(@file_loader, @config.for_linter(linter_class))
      end
    end

    def run(filename, file_content)
      offenses = []
      @linters
        .reject { |linter| linter.excludes_file?(filename) }
        .each do |linter|
        offenses += linter.lint_file(file_content)
      end
      offenses
    end
  end
end
