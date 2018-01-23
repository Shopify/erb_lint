# frozen_string_literal: true

module ERBLint
  module Linters
    # Enforce a single space after `<%` and before `%>` in the erb source.
    # This linter ignores opening erb tags (`<%`) that are followed by a newline,
    # and closing erb tags (`%>`) that are preceeded by a newline.
    class SpaceAroundErbTag < Linter
      include LinterRegistry

      START_SPACES = /\A([[:space:]]*)/m
      END_SPACES = /([[:space:]]*)\z/m

      def offenses(processed_source)
        [].tap do |offenses|
          processed_source.ast.descendants(:erb).each do |erb_node|
            indicator, ltrim, code_node, rtrim = *erb_node
            code = code_node.children.first

            start_spaces = code.match(START_SPACES)&.captures&.first || ""
            if start_spaces.size != 1 && !start_spaces.include?("\n")
              offenses << Offense.new(
                self,
                processed_source.to_source_range(code_node.loc.start, code_node.loc.start + start_spaces.size - 1),
                "Use 1 space after `<%#{indicator&.loc&.source}#{ltrim&.loc&.source}` "\
                "instead of #{start_spaces.size} space#{'s' if start_spaces.size > 1}."
              )
            end

            end_spaces = code.match(END_SPACES)&.captures&.first || ""
            next unless end_spaces.size != 1 && !end_spaces.include?("\n")
            offenses << Offense.new(
              self,
              processed_source.to_source_range(code_node.loc.stop - end_spaces.size + 1, code_node.loc.stop),
              "Use 1 space before `#{rtrim&.loc&.source}%>` "\
              "instead of #{end_spaces.size} space#{'s' if start_spaces.size > 1}."
            )
          end
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, ' ')
        end
      end
    end
  end
end
