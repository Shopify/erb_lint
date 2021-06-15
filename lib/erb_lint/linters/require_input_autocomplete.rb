# frozen_string_literal: true

require 'better_html'
require 'better_html/tree/tag'

module ERBLint
  module Linters
    class RequireInputAutocomplete < Linter
      include LinterRegistry

      TYPES_REQUIRING_AUTOCOMPLETE = [
        "color",
        "date",
        "datetime-local",
        "email",
        "hidden",
        "month",
        "number",
        "password",
        "range",
        "search",
        "tel",
        "text",
        "time",
        "url",
        "week",
      ].freeze

      def run(processed_source)
        parser = processed_source.parser

        parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          autocomplete_attribute = tag.attributes['autocomplete']
          type_attribute = tag.attributes['type']

          next if tag.name != 'input' || autocomplete_present?(autocomplete_attribute)
          next unless type_requires_autocomplete_attribute?(type_attribute)

          add_offense(
            tag_node.to_a[1].loc,
            "Input tag is missing an autocomplete attribute. If no "\
            "autocomplete behaviour is desired, use the value `off` or `nope`.",
            [autocomplete_attribute]
          )
        end
      end

      private

      def type_requires_autocomplete_attribute?(type_attribute)
        type_present = type_attribute.present? && type_attribute.value_node.present?
        type_present && TYPES_REQUIRING_AUTOCOMPLETE.include?(type_attribute.value)
      end

      def autocomplete_present?(autocomplete_attribute)
        autocomplete_attribute.present? && autocomplete_attribute.value_node.present?
      end
    end
  end
end
