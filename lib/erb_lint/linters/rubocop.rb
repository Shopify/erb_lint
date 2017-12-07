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
        @only_cops = config_hash.delete('only')
        custom_config = config_from_hash(config_hash.except('enabled'))
        @config = RuboCop::ConfigLoader.merge_with_default(custom_config, '')
      end

      def lint_file(file_content)
        errors = []
        parser = BetterHtml::Parser.new(file_content, template_language: :html)
        parser.ast.descendants(:erb).each do |erb_node|
          _, _, code_node, = *erb_node
          code = code_node.loc.source.sub(/\A[[:blank:]]*/, '')
          code = "#{' ' * erb_node.loc.column}#{code}"
          code = code.sub(BLOCK_EXPR, '')
          offenses = inspect_content(code)
          offenses&.each do |offense|
            errors << format_error(code_node, offense)
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
        cop_classes =
          if @only_cops.present?
            selected_cops = RuboCop::Cop::Cop.all.select { |cop| cop.match?(@only_cops) }
            RuboCop::Cop::Registry.new(selected_cops)
          elsif @config['Rails']['Enabled']
            RuboCop::Cop::Registry.new(RuboCop::Cop::Cop.all)
          else
            RuboCop::Cop::Cop.non_rails
          end
        RuboCop::Cop::Team.new(cop_classes, @config, extra_details: true, display_cop_names: true)
      end

      def format_error(code_node, offense)
        {
          line: code_node.loc.line + offense.line - 1,
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
