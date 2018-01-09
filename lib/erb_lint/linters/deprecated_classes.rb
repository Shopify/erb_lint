# frozen_string_literal: true

require 'better_html/parser'

module ERBLint
  module Linters
    # Checks for deprecated classes in the start tags of HTML elements.
    class DeprecatedClasses < Linter
      include LinterRegistry

      class RuleSet
        include SmartProperties
        property :suggestion, accepts: String, default: ''
        property :deprecated, accepts: LinterConfig.array_of?(String), default: []
      end

      class ConfigSchema < LinterConfig
        property :rule_set,
          default: [],
          accepts: array_of?(RuleSet),
          converts: to_array_of(RuleSet)
        property :addendum, accepts: String
      end
      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        super
        @addendum = @config.addendum
      end

      def lint_file(file_content)
        errors = []
        parser = build_parser(file_content)
        class_name_with_loc(parser).each do |class_name, loc|
          errors.push(*generate_errors(class_name, loc.line_range))
        end
        text_tags_content(parser).each do |content|
          errors.push(*lint_file(content))
        end
        errors
      end

      private

      def build_parser(file_content)
        BetterHtml::Parser.new(file_content, template_language: :html)
      end

      def class_name_with_loc(parser)
        Enumerator.new do |yielder|
          tags(parser).each do |tag|
            class_value = tag.attributes['class']&.value
            next unless class_value
            class_value.split(' ').each do |class_name|
              yielder.yield(class_name, tag.loc)
            end
          end
        end
      end

      def text_tags_content(parser)
        Enumerator.new do |yielder|
          script_tags(parser)
            .select { |tag| tag.attributes['type']&.value == 'text/html' }
            .each do |tag|
              index = parser.ast.to_a.find_index(tag.node)
              next_node = parser.ast.to_a[index + 1]

              yielder.yield(next_node.loc.source) if next_node.type == :text
            end
        end
      end

      def script_tags(parser)
        tags(parser).select { |tag| tag.name == 'script' }
      end

      def tags(parser)
        tag_nodes(parser).map { |tag_node| BetterHtml::Tree::Tag.from_node(tag_node) }
      end

      def tag_nodes(parser)
        parser.nodes_with_type(:tag)
      end

      def generate_errors(class_name, line_range)
        violated_rules(class_name).map do |violated_rule|
          suggestion = " #{violated_rule[:suggestion]}".rstrip
          message = "Deprecated class `%s` detected matching the pattern `%s`.%s #{@addendum}".strip

          Offense.new(
            self,
            line_range,
            format(message, class_name, violated_rule[:class_expr], suggestion)
          )
        end
      end

      def violated_rules(class_name)
        [].tap do |result|
          @config.rule_set.each do |rule|
            rule.deprecated.each do |deprecated|
              next unless /\A#{deprecated}\z/ =~ class_name

              result << {
                suggestion: rule.suggestion,
                class_expr: deprecated,
              }
            end
          end
        end
      end
    end
  end
end
