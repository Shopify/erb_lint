# frozen_string_literal: true

module ERBLint
  module Linters
    # When `<%` isn't followed by a newline, ensure `%>` isn't preceeded by a newline.
    # When `%>` is preceeded by a newline, indent it at the same level as the corresponding `<%`.
    class ClosingErbTagIndent < Linter
      include LinterRegistry

      START_SPACES = /\A([[:space:]]*)/m
      END_SPACES = /([[:space:]]*)\z/m

      def offenses(processed_source)
        processed_source.ast.descendants(:erb).each_with_object([]) do |erb_node, offenses|
          indicator, ltrim, code_node, rtrim = *erb_node
          code = code_node.children.first

          start_spaces = code.match(START_SPACES)&.captures&.first || ""
          end_spaces = code.match(END_SPACES)&.captures&.first || ""

          start_with_newline = start_spaces.include?("\n")
          end_with_newline = end_spaces.include?("\n")

          if !start_with_newline && end_with_newline
            offenses << Offense.new(
              self,
              processed_source.to_source_range(code_node.loc.stop - end_spaces.size + 1, code_node.loc.stop),
              "Remove newline before `%>` to match start of tag.",
              ' '
            )
          elsif start_with_newline && !end_with_newline
            offenses << Offense.new(
              self,
              processed_source.to_source_range(code_node.loc.stop, code_node.loc.stop),
              "Insert newline before `%>` to match start of tag.",
              "\n"
            )
          elsif start_with_newline && end_with_newline
            current_indent = end_spaces.split("\n", -1).last
            if erb_node.loc.column != current_indent.size
              offenses << Offense.new(
                self,
                processed_source.to_source_range(code_node.loc.stop - current_indent.size + 1, code_node.loc.stop),
                "Indent `%>` on column #{erb_node.loc.column} to match start of tag.",
                ' ' * erb_node.loc.column
              )
            end
          end
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context)
        end
      end
    end
  end
end
