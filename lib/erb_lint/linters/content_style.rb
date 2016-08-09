# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for content style guide violations in the text nodes of HTML files.
    class ContentStyle < Linter
      include LinterRegistry

      def initialize(config)
        @content_ruleset = []
        config.fetch('rule_set', []).each do |rule|
          suggestion = rule.fetch('suggestion', '')
          pattern_description = rule.fetch('pattern_description', '')
          case_insensitive = rule.fetch('case_insensitive', false)
          violation = rule.fetch('violation', [])
          (violation.is_a?(String) ? [violation] : violation).each do |violating_pattern|
            @content_ruleset.push(
              violating_pattern: violating_pattern,
              suggestion: suggestion,
              case_insensitive: case_insensitive,
              pattern_description: pattern_description
            )
          end
        end
        @content_ruleset.freeze
        @addendum = config.fetch('addendum', '')
      end

      def lint_file(file_tree)
        errors = []
        @prior_violations = []
        text_nodes = Parser.get_text_nodes(file_tree)
        text_nodes.each do |text_node|
          # Next if node doesn't contain content
          next unless text_node.text =~ /[^\n\s]/
          content_lines = split_lines(text_node)
          content_lines.each do |line|
            errors.push(*generate_errors(line[:text], line[:number]))
          end
        end
        errors
      end

      private

      def split_lines(text_node)
        lines = []
        current_line_number = text_node.parent.line
        unless text_node.parent.nil?
          s = StringScanner.new(text_node.text)
          if s.check_until(/\n/)
            while line_content = s.scan_until(/\n/)
              lines.push(text: line_content, number: current_line_number)
              current_line_number += 1
            end
          else
            lines.push(text: text_node.text, number: current_line_number)
          end
        end
        lines
      end

      def generate_errors(text, line_number)
        violated_rules(text).map do |violated_rule|
          suggestion = violated_rule[:suggestion]
          pattern_description = violated_rule[:pattern_description]
          violation = pattern_description.empty? ? violated_rule[:violating_pattern] : pattern_description
          {
            line: line_number,
            message: "Don't use `#{violation}`. Do use `#{suggestion}`. #{@addendum}".strip
          }
        end
      end

      def violated_rules(text)
        @content_ruleset.select do |content_rule|
          violating_pattern = content_rule[:violating_pattern]
          suggestion = content_rule[:suggestion]
          case_insensitive = content_rule[:case_insensitive] == true
          if case_insensitive
            /(#{violating_pattern})\b/i.match(text)
          elsif !case_insensitive && suggestion_lowercase(suggestion, violating_pattern)
            # case-sensitive match that ignores case violations that start a sentence
            /[^\.]\s(#{violating_pattern})\b/.match(text)
          else
            # case-sensitive match
            /(#{violating_pattern})\b/.match(text)
          end
        end
      end

      def suggestion_lowercase(suggestion, violating_pattern)
        # Check if the suggestion starts with a lowercase letter and the
        # violation starts with an uppercase letter, in which case the match
        # needs to ignore cases where the violation starts a sentence.
        suggestion.match(/\A[a-z]/) && !violating_pattern.match(/\A[A-Z]/)
      end
    end
  end
end
