# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for instance variables in partials.
    class PartialInstanceVariable < Linter
      include LinterRegistry

      def run(processed_source)
        instance_variable_regex = /\s@\w+/
        return unless processed_source.filename.match?(%r{(\A|.*/)_[^/\s]*\.html\.erb\z})

        erb_node = processed_source.parser.ast.descendants(:erb).find do |node|
          indicator_node, _, code_node, _ = *node
          indicator = indicator_node&.loc&.source
          next false if indicator == "#" || indicator == "%"

          code_node.loc.source.match?(instance_variable_regex)
        end
        return unless erb_node

        match = processed_source.file_content.match(instance_variable_regex, erb_node.loc.begin_pos)

        add_offense(
          processed_source.to_source_range(
            match.begin(0)..processed_source.file_content.size,
          ),
          "Instance variable detected in partial.",
        )
      end
    end
  end
end
