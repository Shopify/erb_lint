# frozen_string_literal: true

require 'psych'
require 'yaml'

module ERBLint
  class ConfigLoader
    DEFAULT_CONFIG_FILENAME = '.erb-lint.yml'
    DEFAULT_LINT_ALL_GLOB = "**/*.html{+*,}.erb"

    attr_reader :runner_config, :config_filename, :enabled_linters

    def self.known_linter_names
      @known_linter_names ||= ERBLint::LinterRegistry.linters
        .map(&:simple_name)
        .map(&:underscore)
    end

    def self.file_loader
      @file_loader ||= ERBLint::FileLoader.new(Dir.pwd)
    end

    def initialize(options = {})
      options.assert_valid_keys(:config, :enabled_linters, :autocorrect)
      @config_filename = options[:config] || DEFAULT_CONFIG_FILENAME
      @enabled_linters = options[:enabled_linters]
      @autocorrect = options[:autocorrect]
      load_config
    end

    def autocorrect?
      @autocorrect
    end

    def excluded?(filename)
      runner_config.global_exclude.any? do |path|
        File.fnmatch?(path, filename)
      end
    end

    def enabled_linter_names
      @enabled_linter_names ||=
        enabled_linters ||
        self.class.known_linter_names
          .select { |name| runner_config.for_linter(name.camelize).enabled? }
    end

    def enabled_linter_classes
      @enabled_linter_classes ||= ERBLint::LinterRegistry.linters
        .select { |klass| linter_can_run?(klass) && enabled_linter_names.include?(klass.simple_name.underscore) }
    end

    def linter_can_run?(klass)
      !autocorrect? || klass.support_autocorrect?
    end

    private

    def load_config
      @runner_config = RunnerConfig.default
      if File.exist?(config_filename)
        cfg = RunnerConfig.new(self.class.file_loader.yaml(config_filename), self.class.file_loader)
        @runner_config.merge!(cfg)
      else
        warn(Rainbow("#{config_filename} not found: using default config").yellow)
      end
      @runner_config.merge!(runner_config_override)
    end

    def runner_config_override
      RunnerConfig.new(
        linters: {}.tap do |linters|
          ERBLint::LinterRegistry.linters.map do |klass|
            linters[klass.simple_name] = { 'enabled' => enabled_linter_classes.include?(klass) }
          end
        end
      )
    end
  end
end
