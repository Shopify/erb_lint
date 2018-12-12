# frozen_string_literal: true

require 'erb_lint'
require 'active_support'
require 'active_support/inflector'
require 'rainbow'


module ERBLint
  class CLI
    STATUS_SUCCESS  = 0
    STATUS_OFFENSES = 1
    STATUS_ERROR    = 2

    attr_reader :args

    def initialize(args = ARGV)
      @args = args
      @out = $stdout
      @err = $stderr
    end

    def run
      files_to_lint =
        if options[:lint_all]
          all_files_to_lint(ConfigLoader::DEFAULT_LINT_ALL_GLOB)
        else
          listed_files_to_lint(args, ConfigLoader::DEFAULT_LINT_ALL_GLOB) do |filename|
            !config_loader.excluded?(filename)
          end
        end

      ensure_files(@args, files_to_lint, parser.option_parser)

      ensure_files_exists(files_to_lint)

      ensure_enabled_linters(config_loader.enabled_linter_classes)

      show_linting_message(formatter, files_to_lint, config_loader.enabled_linter_classes, config_loader.autocorrect?)

      lint_files(Runner.new(ConfigLoader.file_loader, config_loader.runner_config), files_to_lint,
        autocorrect: config_loader.autocorrect?)

      formatter.report(stats)

      if stats.offense_count.positive?
        STATUS_OFFENSES
      else
        STATUS_SUCCESS
      end
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument, Cli::Errors::ExitWithFailure => err
      @err.puts Rainbow(err.message).red
      STATUS_ERROR
    rescue Cli::Errors::ExitWithSuccess => err
      @out.puts err.message
      STATUS_SUCCESS
    rescue => err
      @err.puts Rainbow("#{err.class}: #{err.message}\n#{err.backtrace.join("\n")}").red
      STATUS_ERROR
    end

    private

    def parser
      @parser ||= Cli::OptParser.new(args).parse
    end

    def options
      @options ||= parser.options || {}
    end

    def formatter
      @formatter ||= Formatters::FormatterFactory.build(options.slice(:output, :format, :autocorrect))
    end

    def stats
      @stats ||= Stats.new
    end

    def config_loader
      @config_loader ||= ConfigLoader.new(options.slice(:config, :enabled_linters, :autocorrect))
    end

    def ensure_files_exists(files)
      files.each do |filename|
        raise Cli::Errors::ExitWithFailure, "#{filename}: does not exist" unless File.exist?(filename)
      end
    end

    def ensure_files(args, files, option_parser)
      if !args.empty? && files.empty?
        raise Cli::Errors::ExitWithSuccess, "no files found...\n"
      elsif files.empty?
        raise Cli::Errors::ExitWithSuccess, "no files given...\n#{option_parser}"
      end
    end

    def lint_files(runner, files, options = {})
      files.each do |filename|
        file_content = File.read(filename)
        7.times do # https://github.com/Shopify/erb-lint/pull/36
          processed_source = ProcessedSource.new(filename, file_content)
          runner.run(processed_source)
          break if runner.offenses.empty?

          stats.add_offending_file(Utils::FileUtils.relative_filename(filename), runner.offenses)

          break unless options[:autocorrect]

          corrected_content = autocorrect(processed_source, runner.offenses)
          break unless corrected_content

          file_content = corrected_content
          runner.clear_offenses
        end
        runner.clear_offenses
      end
    end

    def autocorrect(processed_source, offenses)
      corrector = Corrector.new(processed_source, offenses)
      return if corrector.corrections.empty?

      corrector.write
      corrector.update_offenses
      corrector.corrected_content
    end

    def all_files_to_lint(glob)
      @all_files_to_lint ||= begin
        pattern = File.expand_path(glob, Dir.pwd)
        Dir[pattern].select { |filename| !config_loader.excluded?(filename) }
      end
    end

    def listed_files_to_lint(listed_files, glob)
      @listed_files_to_lint ||=
        begin
          listed_files.dup
            .map { |file| Dir.exist?(file) ? Dir[File.join(file, glob)] : file }
            .map { |file| file.include?('*') ? Dir[file] : file }
            .flatten
            .map { |file| File.expand_path(file, Dir.pwd) }
            .select { |filename| block_given? ? yield(filename) : filename }
        end
    end

    def ensure_enabled_linters(enabled_linter_classes)
      if enabled_linter_classes.empty?
        raise Cli::Errors::ExitWithFailure, 'no linter available with current configuration'
      end
    end

    def show_linting_message(formatter, files, enabled_linter_classes, autocorrect)
      if formatter.is_a?(Formatters::DefaultFormatter)
        @out.puts "Linting #{files.size} files with "\
        "#{enabled_linter_classes.size} #{'autocorrectable ' if autocorrect}linters..."
        @out.puts
      end
    end
  end
end
