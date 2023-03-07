# frozen_string_literal: true

module ERBLint
  module Utils
    class InlineConfigs
      def rule_disable_comment_for_lines?(rule, lines)
        lines.match?(/# erblint:disable-line (?<rules>.*#{rule}).*/)
      end

      def disabled_rules(line)
        line.match(/# erblint:disable-line (?<rules>.*) %>/)&.named_captures&.fetch("rules")
      end
    end
  end
end
