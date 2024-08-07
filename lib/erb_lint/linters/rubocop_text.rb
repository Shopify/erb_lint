# frozen_string_literal: true

require_relative "rubocop"

module ERBLint
  module Linters
    class RubocopText < Rubocop
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :only, accepts: array_of?(String)
        property :rubocop_config, accepts: Hash
        property :config_file_path, accepts: String
      end

      self.config_schema = ConfigSchema

      private

      def descendant_nodes(parser)
        erb_nodes = []

        parser.ast.descendants(:text).each do |text_node|
          text_node.descendants(:erb).each do |erb_node|
            erb_nodes << erb_node
          end
        end
        erb_nodes
      end

      def cop_classes
        selected_cops = ::RuboCop::Cop::Registry.all.select { |cop| cop.match?(@only_cops) }

        ::RuboCop::Cop::Registry.new(selected_cops)
      end
    end
  end
end
