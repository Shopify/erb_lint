# frozen_string_literal: true

require 'optparse'

module ERBLint
  module Cli
    class OptParser
      attr_reader :args, :options, :option_parser

      def initialize(args)
        @args = args
        @options = {}
      end

      def parse
        options = {}
        available_formatters = Formatters::FormatterFactory::AVAILABLE_FORMATTERS.keys.join(', ')
        @option_parser = OptionParser.new do |opts|
          opts.banner = 'Usage: erblint [options] [file1, file2, ...]'
          opts.on('--config FILENAME', "Config file [default: #{ConfigLoader::DEFAULT_CONFIG_FILENAME}]") do |config|
            raise Errors::ExitWithFailure, "#{config}: does not exist" unless File.exist?(config)
            options[:config] = config
          end
          opts.on('--lint-all', "Lint all files matching #{ConfigLoader::DEFAULT_LINT_ALL_GLOB}") do |config|
            options[:lint_all] = config
          end
          opts.on('--enable-all-linters', 'Enable all known linters') do
            options[:enabled_linters] = ConfigLoader.known_linter_names
          end
          opts.on('--enable-linters LINTER[,LINTER,...]', Array, 'Only use specified linter',
            "Known linters are: #{ConfigLoader.known_linter_names.join(', ')}") do |linters|
            linters.each do |linter|
              unless ConfigLoader.known_linter_names.include?(linter)
                raise Errors::ExitWithFailure,
                  "#{linter}: not a valid linter name (#{ConfigLoader.known_linter_names.join(', ')})"
              end
            end
            options[:enabled_linters] = linters
          end
          opts.on('--autocorrect', 'Correct offenses that can be corrected automatically (default: false)') do |config|
            options[:autocorrect] = config
          end
          opts.on('--format FORMAT',
            "Select output format. (default: default, available formats: #{available_formatters})") do |format|
            unless format && Formatters::FormatterFactory::AVAILABLE_FORMATTERS.keys.include?(format.to_sym)
              raise Errors::ExitWithFailure,
                "#{format.presence || 'empty'} format is not a valid format (#{available_formatters})"
            end
            options[:format] = format
          end
          opts.on('--output FILE', 'Write output to a file instead of STDOUT.') do |file|
            options[:output] = file
          end
          opts.on_tail('-h', '--help', 'Show this message') do
            raise Errors::ExitWithSuccess, opts
          end
          opts.on_tail('--version', 'Show version') do
            raise Errors::ExitWithSuccess, ERBLint::VERSION
          end
        end
        option_parser.parse!(args)
        @options = options
        self
      end
    end
  end
end
