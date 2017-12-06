# frozen_string_literal: true

require 'better_html'
require 'rubocop'
require 'tempfile'

module ERBLint
  module Linters
    # Run selected rubocop cops on Ruby code
    class Rubocop < Linter
      include LinterRegistry

      # copied from Rails: action_view/template/handlers/erb/erubi.rb
      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def initialize(file_loader, config_hash)
        super
        @enabled_cops = config_hash.delete('only')
        tempfile_from('.erblint-rubocop', config_hash.except('enabled').to_yaml) do |tempfile|
          custom_config = RuboCop::ConfigLoader.load_file(tempfile.path)
          @config = RuboCop::ConfigLoader.merge_with_default(custom_config, '')
        end
      end

      def lint_file(file_content)
        errors = []
        erb = BetterHtml::NodeIterator::HtmlErb.new(file_content)
        erb.tokens.each do |token|
          next unless [:stmt, :expr_literal, :expr_escaped].include?(token.type)
          ruby_code = token.code.sub(BLOCK_EXPR, '')
          ruby_code = ruby_code.sub(/\A[[:blank:]]*/, '')
          ruby_code = "#{' ' * token.location.column}#{ruby_code}"
          offenses = inspect_content(ruby_code)
          offenses&.each do |offense|
            errors << format_error(token, offense)
          end
        end
        errors
      end

      private

      def tempfile_from(filename, content)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end

      def inspect_content(content)
        source = processed_source(content)
        return unless source.valid_syntax?
        offenses = team.inspect_file(source)
        offenses.reject(&:disabled?)
      end

      def processed_source(content)
        RuboCop::ProcessedSource.new(
          content,
          @config.target_ruby_version,
          '(erb)'
        )
      end

      def team
        selected_cops = RuboCop::Cop::Cop.all.select { |cop| cop.match?(@enabled_cops) }
        cop_classes = RuboCop::Cop::Registry.new(selected_cops)
        RuboCop::Cop::Team.new(cop_classes, @config, extra_details: true, display_cop_names: true)
      end

      def format_error(token, offense)
        {
          line: token.location.line + offense.line - 1,
          message: offense.message.strip
        }
      end
    end
  end
end
