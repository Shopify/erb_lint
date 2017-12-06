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
        custom_config = config_from_hash(config_hash.except('enabled'))
        @config = RuboCop::ConfigLoader.merge_with_default(custom_config, '')
      end

      def lint_file(file_content)
        errors = []
        erb = BetterHtml::NodeIterator::HtmlErb.new(file_content)
        erb.tokens.each do |token|
          next unless [:stmt, :expr_literal, :expr_escaped].include?(token.type)
          ruby_code = token.code.sub(BLOCK_EXPR, '')
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

      def config_from_hash(hash)
        inherit_from = hash.delete('inherit_from')
        resolve_inheritance(hash, inherit_from)

        tempfile_from('.erblint-rubocop', hash.to_yaml) do |tempfile|
          RuboCop::ConfigLoader.load_file(tempfile.path)
        end
      end

      def resolve_inheritance(hash, inherit_from)
        base_configs(inherit_from)
          .reverse_each do |base_config|
          base_config.each do |k, v|
            hash[k] = hash.key?(k) ? RuboCop::ConfigLoader.merge(v, hash[k]) : v if v.is_a?(Hash)
          end
        end
      end

      def base_configs(inherit_from)
        regex = URI::DEFAULT_PARSER.make_regexp(%w[http https])
        configs = Array(inherit_from).compact.map do |base_name|
          if base_name =~ /\A#{regex}\z/
            RuboCop::ConfigLoader.load_file(RuboCop::RemoteConfig.new(base_name, Dir.pwd))
          else
            config_from_hash(@file_loader.yaml(base_name))
          end
        end

        configs.compact
      end
    end
  end
end
