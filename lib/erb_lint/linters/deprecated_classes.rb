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

        elements_with_class_attr = file_tree.search('[class]')
        elements_with_class_attr.each do |element|
          class_names = element.attribute('class').value.split(' ')
          line_number = element.attribute('class').line
          class_names.each do |class_name|
            errors.push(*generate_errors(element_name: element.name, class_name: class_name, line_number: line_number))
          end
        end
        errors
      end

      private

      def generate_errors(element_name:, class_name:, line_number:)
        violated_rules(class_name).map do |violated_rule|
          message = 'Deprecated class `%s` detected matching the pattern `%s` on the surrounding `%s` element.'\
            "%s #{@addendum}".strip
          suggestion = " #{violated_rule[:suggestion]}".rstrip

          {
            line: line_number,
            message: format(message, class_name, violated_rule[:class_expr], element_name, suggestion)
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
