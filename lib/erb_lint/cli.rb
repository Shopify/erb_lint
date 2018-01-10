# frozen_string_literal: true

require 'erb_lint'
require 'active_support'
require 'active_support/inflector'
require 'optparse'
require 'psych'
require 'yaml'
require 'colorize'

module ERBLint
  class CLI
    DEFAULT_CONFIG_FILENAME = '.erb-lint.yml'
    DEFAULT_LINT_ALL_GLOB = "**/*.html{+*,}.erb"

    class ExitWithFailure < RuntimeError; end
    class ExitWithSuccess < RuntimeError; end

    def initialize
      @options = {}
      @config = nil
      @files = []
    end

    def run(args = ARGV)
      load_options(args)
      @files = args.dup

      if lint_files.empty?
        success!("no files given...\n#{option_parser}")
      end

      load_config
      ensure_files_exist(lint_files)

      puts "Linting #{lint_files.size} files with #{enabled_linter_classes.size} linters..."
      puts

      errors_found = false
      runner_config = @config.merge(runner_config_override)
      runner = ERBLint::Runner.new(file_loader, runner_config)
      lint_files.each do |filename|
        processed_source = ERBLint::ProcessedSource.new(filename, File.read(filename))
        offenses = runner.run(processed_source)
        offenses.each do |offense|
          puts <<~EOF
            #{offense.message}
            In file: #{relative_filename(filename)}:#{offense.line_range.begin}

          EOF
          errors_found = true
        end
      end

      if errors_found
        warn "Errors were found in ERB files".red
      else
        puts "No errors were found in ERB files".green
      end

      !errors_found
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument, ExitWithFailure => e
      warn e.message.red
      false
    rescue ExitWithSuccess => e
      puts e.message
      true
    rescue => e
      warn "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}".red
      false
    end

    private

    def config_filename
      @config_filename ||= @options[:config] || DEFAULT_CONFIG_FILENAME
    end

    def load_config
      if File.exist?(config_filename)
        @config = RunnerConfig.new(file_loader.yaml(config_filename))
      else
        warn "#{config_filename} not found: using default config".yellow
        @config = RunnerConfig.default
      end
    rescue Psych::SyntaxError => e
      failure!("error parsing config: #{e.message}")
    end

    def file_loader
      @file_loader ||= ERBLint::FileLoader.new(Dir.pwd)
    end

    def load_options(args)
      option_parser.parse!(args)
    end

    def lint_files
      if @options[:lint_all]
        pattern = File.expand_path(DEFAULT_LINT_ALL_GLOB, Dir.pwd)
        Dir[pattern]
      else
        @files.map { |f| f.include?('*') ? Dir[f] : f }.flatten.map { |f| File.expand_path(f, Dir.pwd) }
      end
    end

    def failure!(msg)
      raise ExitWithFailure, msg
    end

    def success!(msg)
      raise ExitWithSuccess, msg
    end

    def ensure_files_exist(files)
      files.each do |filename|
        unless File.exist?(filename)
          failure!("#{filename}: does not exist")
        end
      end
    end

    def known_linter_names
      @known_linter_names ||= ERBLint::LinterRegistry.linters
        .map(&:simple_name)
        .map(&:underscore)
    end

    def enabled_linter_names
      @enabled_linter_names ||=
        @options[:enabled_linters] ||
        known_linter_names.select { |name| @config.for_linter(name.camelize).enabled? }
    end

    def enabled_linter_classes
      @enabled_linter_classes ||= ERBLint::LinterRegistry.linters
        .select { |klass| enabled_linter_names.include?(klass.simple_name.underscore) }
    end

    def relative_filename(filename)
      filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
    end

    def runner_config_override
      if @options[:enabled_linters].present?
        RunnerConfig.new(
          linters: {}.tap do |linters|
            ERBLint::LinterRegistry.linters.map do |klass|
              linters[klass.simple_name] = { 'enabled' => enabled_linter_classes.include?(klass) }
            end
          end
        )
      else
        RunnerConfig.new
      end
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: erblint [options] [file1, file2, ...]"

        opts.on("--config FILENAME", "Config file [default: #{DEFAULT_CONFIG_FILENAME}]") do |config|
          if File.exist?(config)
            @options[:config] = config
          else
            failure!("#{config}: does not exist")
          end
        end

        opts.on("--lint-all", "Lint all files matching #{DEFAULT_LINT_ALL_GLOB}") do |config|
          @options[:lint_all] = config
        end

        opts.on("--enable-all-linters", "Enable all known linters") do
          @options[:enabled_linters] = known_linter_names
        end

        opts.on("--enable-linters LINTER[,LINTER,...]", Array,
          "Only use specified linter", "Known linters are: #{known_linter_names.join(', ')}") do |linters|
          linters.each do |linter|
            unless known_linter_names.include?(linter)
              failure!("#{linter}: not a valid linter name (#{known_linter_names.join(', ')})")
            end
          end
          @options[:enabled_linters] = linters
        end

        opts.on_tail("-h", "--help", "Show this message") do
          success!(opts)
        end

        opts.on_tail("--version", "Show version") do
          success!(ERBLint::VERSION)
        end
      end
    end
  end
end
