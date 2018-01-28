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
              processed_source.to_source_range(start_solidus.loc.start, start_solidus.loc.stop),
              "Tag `#{tag.name}` is self-closing, it must not start with `</`.",
              ''
            )
          end

          if !tag.self_closing?
            offenses << Offense.new(
              self,
              processed_source.to_source_range(tag_node.loc.stop, tag_node.loc.stop - 1),
              "Tag `#{tag.name}` is self-closing, it must end with `/>`.",
              '/'
            )
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
