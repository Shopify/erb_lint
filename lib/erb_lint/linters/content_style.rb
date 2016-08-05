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
        inner_text = select_text_children(html_elements(file_tree))
        outer_text = select_text_children(file_tree)
        all_text = (outer_text + inner_text)
        # Assumes the immediate parent is on the same line. Nokogiri bug
        # prevents retrieving line number from text node:
        # https://github.com/sparklemotion/nokogiri/issues/1493
        all_text.each do |text_node|
          # Skips nodes that contain only a newline
          next if text_node.text == '\n'
          line_number = calculate_line_number(text_node)
          errors.push(*generate_errors(strip_next_lines(text_node.text), line_number))
        end
        errors
      end

      private

      def calculate_line_number(text_node)
        unless text_node.parent.nil?
          s = StringScanner.new(text_node.text)
          # Scan until character that's not newline or space
          newlines = s.scan_until(/[^\\n\s]/) || ''
          @newline_count = newlines.scan(/\n/).size || 0
          text_node.parent.line + @newline_count
        end
      end

      # To avoid errors showing the wrong line number in Policial
      def strip_next_lines(text)
        if text =~ /\n/
          if text[0] == '\n'
            # Strips out content after any newlines following the
            # newline_count number of newlines.
            text.match(/\A.*\n{#{@newline_count}}.*/).to_s
          else
            # Strips out the content after any newlines.
            text.match(/(.+?)(?=\n)/).to_s
          end
        else
          text
        end
      end

      def select_text_children(source)
        source.children.select(&:text?) || []
      end

      def html_elements(file_tree)
        Nokogiri::XML::NodeSet.new(file_tree.document, file_tree.search('*'))
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
          violation = content_rule[:violating_pattern]
          suggestion = content_rule[:suggestion]
          rule_case_insensitive = content_rule[:case_insensitive] == true
          # Next if this violation is contained within another one that has occurred earlier
          # in the list, e.g. "Store's admin" violates "store's admin" and "Store"
          next if @prior_violations.to_s.include?(violation)
          if rule_case_insensitive
            # case-insensitive_match
            match_violation(/(#{violation})\b/i, text)
          elsif !rule_case_insensitive && suggestion_lowercase(suggestion, violation)
            # case-sensitive match that ignores case violations that start a sentence
            match_violation(/\w (#{violation})\b/, text)
          else
            # case-sensitive match
            match_violation(/(#{violation})\b/, text)
          end
        end
      end

      def match_violation(regex, text)
        regex.match(text) && record_prior_violation(regex, text)
      end

      def suggestion_lowercase(suggestion, violation)
        # Check if the suggestion starts with a lowercase letter and the
        # violation starts with an uppercase letter, in which case the match
        # needs to ignore cases where the violation starts a sentence.
        suggestion.match(/\p{Lower}/) && !violation.match(/\p{Lower}/)
      end

      def record_prior_violation(regex, text)
        @prior_violations.push(regex.match(text).captures)
      end
    end
  end
end
