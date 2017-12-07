# frozen_string_literal: true

require 'active_support'

module ERBLint
  class LinterConfig
    def initialize(config = {})
      @config = config.dup.deep_stringify_keys
    end

    def to_hash
      @config.dup
    end

    def [](key)
      @config[key.to_s]
    end

    def fetch(key, *args, &block)
      @config.fetch(key.to_s, *args, &block)
    end

    def enabled?
      !!@config['enabled']
    end

    def excludes_file?(filename)
      fetch(:exclude, []).any? do |path|
        File.fnmatch?(path, filename)
      end
    end
  end
end
