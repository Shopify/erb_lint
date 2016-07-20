# frozen_string_literal: true

module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    def initialize(config = {})
      @config = default_config.merge(config || {})

      LinterRegistry.load_custom_linters
      @linters = LinterRegistry.linters.select { |linter_class| linter_enabled?(linter_class) }
      @linters.map! do |linter_class|
        linter_config = @config['linters'][linter_class.simple_name]
        linter_class.new(linter_config)
      end
    end

    def run(filename, file_content)
      linters_for_file = @linters.select { |linter| !linter_excludes_file?(linter, filename) }
      linters_for_file.map do |linter|
        {
          linter_name: linter.class.simple_name,
          errors: linter.lint_file(file_content)
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

    def linter_excludes_file?(linter, filename)
      excluded_filepaths = linter['exclude'] || []
      excluded_filepaths.each do |path|
        if File.fnmatch?(path, filename)
          return true
        end
      end
      false
    end

    def default_config
      {
        'linters' => {
          'FinalNewline' => {
            'enabled' => true
          }
        }
      }
    end
  end
end
