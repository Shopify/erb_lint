# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require 'better_html/node_iterator'

module ERBLint
  module Linters
    # Checks for deprecated classes in the start tags of HTML elements.
    class DeprecatedClasses < Linter
      include LinterRegistry

      def initialize(config)
        @deprecated_ruleset = []
        config.fetch('rule_set', []).each do |rule|
          suggestion = rule.fetch('suggestion', '')
          rule.fetch('deprecated', []).each do |class_expr|
            @deprecated_ruleset.push(
              class_expr: class_expr,
              suggestion: suggestion
            )
          end
        end
        @deprecated_ruleset.freeze

        @addendum = config.fetch('addendum', '')
      end

      def lint_file(file_content)
        errors = []
        iterator = BetterHtml::NodeIterator.new(file_content, template_language: :html)
        each_class_name(iterator) do |class_name, line|
          errors.push(*generate_errors(class_name, line))
        end
        errors
      end

      private

      def each_class_name(iterator)
        each_element(iterator) do |element|
          klass = element.find_attr('class')
          next unless klass
          klass.value_without_quotes.split(' ').each do |class_name|
            yield class_name, klass.name_parts.first.location.line
          end
        end
      end

      def each_element(iterator)
        iterator.nodes.each do |node|
          yield node if node.element?
        end
      end

      def generate_errors(class_name, line_number)
        violated_rules(class_name).map do |violated_rule|
          suggestion = " #{violated_rule[:suggestion]}".rstrip
          message = "Deprecated class `%s` detected matching the pattern `%s`.%s #{@addendum}".strip
          {
            line: line_number,
            message: format(message, class_name, violated_rule[:class_expr], suggestion)
          }
        end
      end

      def violated_rules(class_name)
        @deprecated_ruleset.select do |deprecated_rule|
          /\A#{deprecated_rule[:class_expr]}\z/.match(class_name)
        end
      end
    end
  end
end
