# frozen_string_literal: true

module ERBLint
  module Linters
    class RubocopText < Rubocop
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :only, accepts: array_of?(String)
        property :rubocop_config, accepts: Hash
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

      def team
        selected_cops = RuboCop::Cop::Cop.all.select { |cop| cop.match?(@only_cops) }
        cop_classes = RuboCop::Cop::Registry.new(selected_cops)

        RuboCop::Cop::Team.new(cop_classes, @rubocop_config, extra_details: true, display_cop_names: true)
      end
    end
  end
end
