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
          regex_description = rule.fetch('regex_description', '')
          case_insensitive = rule.fetch('case_insensitive', false)
          violation = rule.fetch('violation', [])
          (violation.is_a?(String) ? [violation] : violation).each do |violating_pattern|
            @content_ruleset.push(
              violating_pattern: violating_pattern,
              suggestion: suggestion,
              case_insensitive: case_insensitive,
              regex_description: regex_description
            )
          end
        end
        @content_ruleset.freeze
        @addendum = config.fetch('addendum', '')
      end

      def lint_file(file_tree)
        errors = []
        @prior_violations = []
        all_text = Parser.get_text_nodes(file_tree)
        all_text.each do |text_node|
          # Next if node doesn't contain content
          next if text_node.text =~ /\A(\n|\s)*\z/
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
        current_line_number = 1
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
          regex_description = violated_rule[:regex_description]
          violation = if !regex_description.empty?
                        regex_description
                      else
                        violated_rule[:violating_pattern]
                      end
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
          # Next if this violation is contained within another one that has occurred earlier
          # in the list, e.g. "Store's admin" violates "store's admin" and "Store"
          next if @prior_violations.to_s.include?(violating_pattern)
          if case_insensitive
            match_violation(/(#{violating_pattern})\b/i, text)
          elsif !case_insensitive && suggestion_lowercase(suggestion, violating_pattern)
            # case-sensitive match that ignores case violations that start a sentence
            match_violation(/\w (#{violating_pattern})\b/, text)
          else
            # case-sensitive match
            match_violation(/(#{violating_pattern})\b/, text)
          end
        end
      end

      def match_violation(regex, text)
        regex.match(text) && record_prior_violation(regex, text)
      end

      def suggestion_lowercase(suggestion, violating_pattern)
        # Check if the suggestion starts with a lowercase letter and the
        # violation starts with an uppercase letter, in which case the match
        # needs to ignore cases where the violation starts a sentence.
        suggestion.match(/\p{Lower}/) && !violating_pattern.match(/\p{Lower}/)
      end

      def record_prior_violation(regex, text)
        @prior_violations.push(regex.match(text).captures)
      end
    end
  end
end
