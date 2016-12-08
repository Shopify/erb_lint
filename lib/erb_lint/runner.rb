# frozen_string_literal: true

module ERBLint
  # Runs all enabled linters against an html.erb file.
  class Runner
    def initialize(config = {})
      @config = default_config.merge(config || {})

      LinterRegistry.load_custom_linters
      @linters = LinterRegistry.linters.select { |linter_class| linter_enabled?(linter_class) }
      @linters.map! do |linter_class|
        linter_config = @config.dig('linters', linter_class.simple_name)
        linter_class.new(linter_config)
      end
    end

    def run(filename, file_content)
      file_tree = begin
        HTMLParser.parse(file_content)
      rescue HTMLParser::ParseError
        return [
          { linter_name: 'HTMLValidity', errors: [
            { line: 1,
              message: 'File is not HTML valid and could not be successfully parsed.
              Ensure all tags are properly closed.' }
          ] }
        ]
      end

      ruby_ast = begin
        ERBParser.parse(file_content)
      rescue ERBParser::ParseError => e
        return [{
          linter_name: 'ERBValidity',
          errors: [{ line: 1, message: e.message }]
        }]
      end

      linters_for_file = @linters.select { |linter| !linter_excludes_file?(linter, filename) }
      linters_for_file.map do |linter|
        {
          linter_name: linter.class.simple_name,
          errors: linter.lint_file(file_tree, ruby_ast)
        }
      end
    end

    private

    def linter_enabled?(linter_class)
      linter_config = @config.dig('linters', linter_class.simple_name)
      return false if linter_config.nil?
      linter_config['enabled'] || false
    end

    def linter_excludes_file?(linter, filename)
      excluded_filepaths = @config.dig('linters', linter.class.simple_name, 'exclude') || []
      excluded_filepaths.each do |path|
        return true if File.fnmatch?(path, filename)
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
