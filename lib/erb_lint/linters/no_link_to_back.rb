# frozen_string_literal: true

require "better_html"

module ERBLint
  module Linters
    # Disallow `:back` option in `link_to` like methods.
    # It potentially causes XSS attack by HTTP Referer pollution.
    class NoLinkToBack < Linter
      include LinterRegistry

      class UnKnownMethodNameError < StandardError; end

      def run(processed_source)
        processed_source
          .parser
          .ast
          .descendants(:erb)
          .flat_map { |erb| erb.descendants(:code).to_a }
          .map do |code|
            {
              loc: code.loc,
              node: BetterHtml::TestHelper::RubyNode.parse(code.loc.source),
              block: code.loc.source.rstrip.end_with?("do"),
            }
          end
          .select { |code| link_to_like_method?(code) }
          .map do |code|
            {
              **code,
              method_name: extract_method_name(code),
            }
          end
          .select { |code| link_to_with_back?(code) }
          .each do |code|
          add_offense(
            processed_source.to_source_range(
              code[:loc].begin_pos..code[:loc].end_pos,
            ),
            "Don't use :back option in #{code[:node].method_name} method. " \
              "It potentially causes XSS attack by HTTP Referer pollution.",
          )
        end
      end

      private

      def link_to_like_method?(code)
        link_to?(code[:node]) || link_to_if?(code[:node]) || link_to_unless?(code[:node])
      end

      def extract_method_name(code)
        if link_to?(code[:node])
          :link_to
        elsif link_to_if?(code[:node])
          :link_to_if
        elsif link_to_unless?(code[:node])
          :link_to_unless
        else
          raise UnKnownMethodNameError, "Unknown method name: #{code[:node].method_name}"
        end
      end

      def link_to_with_back?(code)
        method_index = code[:node].children.find_index { |c| c == code[:method_name] }
        arguments = code[:node].children[method_index + 1..-1]
        index = option_index_in_signature(code)
        return false if arguments[index].nil?

        arguments[index].is_a?(BetterHtml::TestHelper::RubyNode) &&
          arguments[index].type?(:sym) &&
          arguments[index].children.first.to_sym == :back
      end

      def option_index_in_signature(code)
        if code[:method_name] == :link_to
          if code[:block]
            0
          else
            1
          end
        else
          2
        end
      end

      def link_to?(node)
        !node.nil? && node.type == :send && node.method_name == :link_to
      end

      def link_to_if?(node)
        !node.nil? && node.type == :send && node.method_name == :link_to_if
      end

      def link_to_unless?(node)
        !node.nil? && node.type == :send && node.method_name == :link_to_unless
      end
    end
  end
end
