# frozen_string_literal: true

module ERBLint
  # Loads file from disk
  class FileLoader
    attr_reader :base_path

    def initialize(base_path)
      @base_path = base_path
    end

    def yaml(filename)
      YAML.safe_load(read_content(filename), [Regexp], [], false, filename) || {}
    rescue Psych::SyntaxError
      {}
    end

    private

    def join(filename)
      File.join(base_path, filename)
    end

    def read_content(filename)
      File.read(join(filename))
    end
  end
end
