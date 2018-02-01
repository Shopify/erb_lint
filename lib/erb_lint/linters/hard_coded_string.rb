# frozen_string_literal: true

require 'better_html/tree/tag'
require 'active_support/core_ext/string/inflections'

module ERBLint
  module Linters
    # Checks for hardcoded strings. Useful if you want to ensure a string can be translated using i18n.
    class HardCodedString < Linter
      include LinterRegistry

      MissingCorrector = Class.new(StandardError)

      class ConfigSchema < LinterConfig
        property :corrector, accepts: Hash, required: false, default: {}
      end
      self.config_schema = ConfigSchema

      def offenses(processed_source)
        hardcoded_strings = processed_source.ast.descendants(:text).each_with_object([]) do |text_node, to_check|
          next if javascript?(processed_source, text_node)

          offended_strings = text_node.to_a.select { |node| relevant_node(node) }
          offended_strings.each do |offended_string|
            offended_string.split("\n").each do |str|
              to_check << [text_node, str] unless str.empty?
            end
          end
        end

        hardcoded_strings.compact.map do |text_node, offended_str|
          range_begin, range_stop = find_range(text_node, offended_str)
          source_range = processed_source.to_source_range(range_begin, range_stop)

          Offense.new(
            self,
            source_range,
            message(source_range.source)
          )
        end
      end

      def find_range(node, str)
        match = node.loc.source.match(Regexp.new(Regexp.quote(str.strip)))
        return unless match

        range_begin = match.begin(0) + node.loc.start
        range_end   = match.end(0) + node.loc.start - 1
        [range_begin, range_end]
      end

      def autocorrect(processed_source, offense)
        string = offense.source_range.source
        return unless klass = load_corrector
        return unless string.strip.length > 1

        corrector = klass.new(processed_source.filename, offense.source_range)
        node = RuboCop::AST::StrNode.new(:str, [string])
        corrector.autocorrect(node, tag_start: '<%= ', tag_end: ' %>')
      rescue MissingCorrector
        nil
      end

      private

      def load_corrector
        require @config['corrector'].fetch('path') { raise MissingCorrector }

        @config['corrector'].fetch('name').safe_constantize
      end

      def javascript?(processed_source, text_node)
        ast = processed_source.parser.ast.to_a
        index = ast.find_index(text_node)

        previous_node = ast[index - 1]

        if previous_node.type == :tag
          tag = BetterHtml::Tree::Tag.from_node(previous_node)

          tag.name == "script" && !tag.closing?
        end
      end

      def relevant_node(inner_node)
        if inner_node.is_a?(String)
          inner_node.strip.empty? ? false : inner_node
        else
          false
        end
      end

      def message(string)
        stripped_string = string.strip

        if stripped_string.length > 1
          "String not translated: #{stripped_string}"
        else
          "Consider using Rails helpers to move out the single character `#{stripped_string}` from the html."
        end
      end
    end
  end
end
