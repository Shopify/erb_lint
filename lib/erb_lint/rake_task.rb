# frozen_string_literal: true

require "rake"
require "rake/tasklib"
require "erb_lint/cli"

module ERBLint
  # Defines Rake tasks for use.
  class RakeTask < ::Rake::TaskLib
    def initialize(name = :erb_lint, cli: ERBLint::CLI.new)
      super()
      @name = name
      @cli = cli
      @arguments = block_given? ? yield : ["--lint-all"]

      define
    end

    private

    attr_reader :name, :arguments, :cli

    def define
      desc("Run ERB Lint")
      task(name) { run }
    end

    def run
      rake_output_message("Running ERB Lint...")
      cli.run(arguments)
    end
  end
end
