# frozen_string_literal: true

module ERBLint
  class Linter
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

      def lint_file(file_tree)
        errors = []

        html_elements = file_tree.search('*').select { |element| element.name != 'erb' }
        html_elements.each do |html_element|
          html_element.attribute_nodes.select { |attribute| attribute.name.casecmp('class') == 0 }.each do |class_attr|
            Parser.remove_escaped_erb_tags(class_attr.value).split(' ').each do |class_name|
              errors.push(*generate_errors(html_element, class_name, line_number: class_attr.line))
            end
          end
        end
        errors
      end

      private

      def generate_errors(element, class_name, line_number:)
        violated_rules(class_name).map do |violated_rule|
          suggestion = " #{violated_rule[:suggestion]}".rstrip
          message = 'Deprecated class `%s` detected matching the pattern `%s` on the surrounding `%s` element.'\
            "%s #{@addendum}".strip
          {
            line: line_number,
            message: format(message, class_name, violated_rule[:class_expr], element.name, suggestion)
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
