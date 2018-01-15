# frozen_string_literal: true

require 'better_html/tree/tag'

module ERBLint
  module Linters
    # Checks for hardcoded strings. Useful if you want to ensure a string can be translated using i18n.
    class HardCodedString < Linter
      include LinterRegistry

      def offenses(processed_source)
        hardcoded_strings = processed_source.ast.descendants(:text).each_with_object([]) do |text_node, to_check|
          next if javascript?(processed_source, text_node)

          offended_str = text_node.to_a.find { |node| relevant_node(node) }
          to_check << [text_node, offended_str] if offended_str
        end

        hardcoded_strings.compact.map do |text_node, offended_str|
          Offense.new(
            self,
            processed_source.to_source_range(text_node.loc.start, text_node.loc.stop),
            message(offended_str)
          )
        end
      end

      private

      def javascript?(processed_source, text_node)
        ast = processed_source.parser.ast.to_a
        index = ast.find_index(text_node)

        previous_node = ast[index - 1]

        if previous_node.type == :tag
          tag = BetterHtml::Tree::Tag.from_node(previous_node)

          tag.name == "script" && !tag.closing?
        end
      end

      def relevant_node(inner_node)
        if inner_node.is_a?(String)
          inner_node.strip.empty? ? false : inner_node
        else
          false
        end
      end

      def message(string)
        stripped_string = string.strip

        if stripped_string.length > 1
          "String not translated: #{stripped_string}"
        else
          "Consider using Rails helpers to move out the single character `#{stripped_string}` from the html."
        end
      end
    end
  end
end
