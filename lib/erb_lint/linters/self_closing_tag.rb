# frozen_string_literal: true

module ERBLint
  module Linters
    # Warns when a tag is not self-closed properly.
    class SelfClosingTag < Linter
      include LinterRegistry

      SELF_CLOSING_TAGS = %w(
        area base br col command embed hr input keygen
        link menuitem meta param source track wbr img
      )

      def offenses(processed_source)
        processed_source.ast.descendants(:tag).each_with_object([]) do |tag_node, offenses|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          next unless SELF_CLOSING_TAGS.include?(tag.name)

          if tag.closing?
            start_solidus = tag_node.children.first
            offenses << Offense.new(
              self,
              start_solidus.loc,
              "Tag `#{tag.name}` is self-closing, it must not start with `</`.",
              ''
            )
          end

          next if tag.self_closing?
          offenses << Offense.new(
            self,
            tag_node.loc.end.offset(-1),
            "Tag `#{tag.name}` is self-closing, it must end with `/>`.",
            '/'
          )
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
