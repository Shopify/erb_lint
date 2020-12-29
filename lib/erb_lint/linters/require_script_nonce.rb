# frozen_string_literal: true

require 'better_html'
require 'better_html/tree/tag'

module ERBLint
  module Linters
    # Allow inline script tags in ERB that have a nonce attribute.
    # This only validates inline <script> tags, as well as rails helpers like javascript_tag.
    class RequireScriptNonce < Linter
      include LinterRegistry

      def run(processed_source)
        parser = processed_source.parser

        find_html_script_tags(parser)
        find_rails_helper_script_tags(parser)
      end

      private

      def find_html_script_tags(parser)
        parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          next if tag.closing?
          next unless tag.name == 'script'

          type_attribute = tag.attributes['type']
          # type attribute = something other than text/javascript
          next if type_attribute &&
            type_attribute.value_node.present? &&
            type_attribute.value_node.to_a[1] != 'text/javascript'

          nonce_attribute = tag.attributes['nonce']
          nonce_present = nonce_attribute.present? && nonce_attribute.value_node.present?

          next if nonce_present
          name_node = tag_node.to_a[1]
          add_offense(
            name_node.loc,
            "Missing a nonce attribute. Use request.content_security_policy_nonce",
            [nonce_attribute]
          )
        end
      end

      def find_rails_helper_script_tags(parser)
        parser.ast.descendants(:erb).each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          indicator = indicator_node&.loc&.source
          next if indicator == '#'
          source = code_node.loc.source

          ruby_node =
            begin
              BetterHtml::TestHelper::RubyNode.parse(source)
            rescue ::Parser::SyntaxError
              nil
            end

          next unless ruby_node
          send_node = ruby_node.descendants(:send).first
          next unless send_node&.method_name?(:javascript_tag) ||
            send_node&.method_name?(:javascript_include_tag) ||
            send_node&.method_name?(:javascript_pack_tag)

          next if source.include?("nonce: true")

          add_offense(
            erb_node.loc,
            "Missing a nonce attribute. Use nonce: true",
            [erb_node, send_node]
          )
        end
      end
    end
  end
end
