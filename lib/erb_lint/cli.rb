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

    class Stats
      attr_accessor :found, :corrected
      def initialize
        @found = 0
        @corrected = 0
      end
    end

    def initialize
      @options = {}
      @config = nil
      @files = []
      @stats = Stats.new
    end

    def run(args = ARGV)
      load_options(args)
      @files = args.dup

      if lint_files.empty?
        success!("no files given...\n#{option_parser}")
      end

      load_config
      ensure_files_exist(lint_files)

      if enabled_linter_classes.empty?
        failure!('no linter available with current configuration')
      end

      puts "Linting #{lint_files.size} files with "\
        "#{enabled_linter_classes.size} #{'autocorrectable ' if autocorrect?}linters..."
      puts

      runner_config = @config.merge(runner_config_override)
      runner = ERBLint::Runner.new(file_loader, runner_config)
      lint_files.each do |filename|
        run_with_corrections(runner, filename)
      end

      if @stats.corrected > 0
        if @stats.found > 0
          warn "#{@stats.corrected} error(s) corrected and #{@stats.found} error(s) remaining in ERB files".red
        else
          puts "#{@stats.corrected} error(s) corrected in ERB files".green
        end
      elsif @stats.found > 0
        warn "#{@stats.found} error(s) were found in ERB files".red
      else
        puts "No errors were found in ERB files".green
      end

      @stats.found == 0
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

    def autocorrect?
      @options[:autocorrect]
    end

    def run_with_corrections(runner, filename)
      file_content = File.read(filename)
      processed_source = ERBLint::ProcessedSource.new(filename, file_content)
      offenses = runner.run(processed_source)

      if offenses.any? && autocorrect?
        corrector = correct(processed_source, offenses)
        processed_source = ERBLint::ProcessedSource.new(filename, corrector.corrected_content)
        offenses = runner.run(processed_source)

        @stats.corrected += corrector.corrections.size

        if file_content != corrector.corrected_content
          File.open(filename, "wb") do |file|
            file.write(corrector.corrected_content)
          end

          if corrector.corrections.any?
            puts <<~EOF
              #{corrector.corrections.size} offense(s) corrected
              In file: #{relative_filename(filename)}

            EOF
          end
        else
          puts <<~EOF.red
            Attempted autocorrect but file remains unchanged: #{relative_filename(filename)}

          EOF
        end
      end

      offenses.each do |offense|
        puts <<~EOF
          #{offense.message}#{' (not autocorrected)'.red if autocorrect?}
          In file: #{relative_filename(filename)}:#{offense.line_range.begin}

        EOF

        @stats.found += 1
      end
    end

    def correct(processed_source, offenses)
      corrector = ERBLint::Corrector.new(processed_source, offenses)
      failure!(corrector.diagnostics.join(', ')) if corrector.diagnostics.any?
      corrector
    end

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
        known_linter_names
          .select { |name| @config.for_linter(name.camelize).enabled? }
    end

    def enabled_linter_classes
      @enabled_linter_classes ||= ERBLint::LinterRegistry.linters
        .select { |klass| linter_can_run?(klass) && enabled_linter_names.include?(klass.simple_name.underscore) }
    end

    def linter_can_run?(klass)
      !autocorrect? || klass.support_autocorrect?
    end

    def relative_filename(filename)
      filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
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

        opts.on("--autocorrect", "Correct offenses that can be corrected automatically (default: false)") do |config|
          @options[:autocorrect] = config
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
