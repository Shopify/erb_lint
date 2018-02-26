# frozen_string_literal: true

require 'better_html/tree/tag'
require 'active_support/core_ext/string/inflections'

module ERBLint
  module Linters
    # Checks for hardcoded strings. Useful if you want to ensure a string can be translated using i18n.
    class HardCodedString < Linter
      include LinterRegistry

      ForbiddenCorrector = Class.new(StandardError)
      MissingCorrector = Class.new(StandardError)

      ALLOWED_CORRECTORS = %w(
        I18nCorrector
        RuboCop::I18nCorrector
      )

      class ConfigSchema < LinterConfig
        property :corrector, accepts: Hash, required: false, default: {}
      end
      self.config_schema = ConfigSchema

      def run(processed_source)
        hardcoded_strings = processed_source.ast.descendants(:text).each_with_object([]) do |text_node, to_check|
          next if javascript?(processed_source, text_node)

          text_node.to_a.each do |node|
            unless string = relevant_node(node)
              to_check << nil
              next
            end

            if node.is_a?(String)
              string.split("\n").each do |str|
                append_to_check(to_check, str, text_node)
              end
            elsif node&.type == :erb
              append_to_check(to_check, string, text_node)
            end
          end
        end

        clear_solo_erb_code(hardcoded_strings).each do |text_node, offended_str|
          range = find_range(text_node, offended_str)
          source_range = processed_source.to_source_range(range)

          add_offense(
            source_range,
            message(source_range.source)
          )
        end
      end

      def find_range(node, str)
        match = node.loc.source.match(Regexp.new(Regexp.quote(str.strip)))
        return unless match

        range_begin = match.begin(0) + node.loc.begin_pos
        range_end   = match.end(0) + node.loc.begin_pos
        (range_begin...range_end)
      end

      def autocorrect(processed_source, offense)
        string = offense.source_range.source
        return unless klass = load_corrector
        return unless string.strip.length > 1

        corrector = klass.new(processed_source.filename, offense.source_range)

        node = RuboCop::ProcessedSource.new(
          replace_erb_symbols_for_interpolation(string),
          RUBY_VERSION.to_f,
        ).ast

        node = node.each_child_node(:str).first if node.type != :str

        corrector.autocorrect(node, tag_start: '<%= ', tag_end: ' %>')
      rescue MissingCorrector
        nil
      end

      private

      def append_to_check(to_check, str, text_node)
        return unless check_string?(str)

        if append_to_last_to_check?(to_check, str, text_node)
          to_check.last[1] += str
        else
          to_check << [text_node, str]
        end
      end

      def clear_solo_erb_code(hardcoded_strings)
        hardcoded_strings.compact.delete_if do |text_node, offended_str|
          text_node.descendants(:erb).any? { |node| node.loc.source == offended_str }
        end
      end

      def append_to_last_to_check?(to_check, str, text_node)
        return false if to_check.last.nil?

        to_check_string = to_check.last[1]
        to_check_string_range = find_range(text_node, to_check_string)
        return false if to_check_string_range.nil?

        str_range = find_range(text_node, str)
        str_range.begin - 1 <= to_check_string_range.end
      end

      def replace_erb_symbols_for_interpolation(string)
        string = string.gsub('<%= ', '#{').gsub('<% ', '#{').gsub(' %>', '}')
        "\"#{string}\""
      end

      def check_string?(str)
        string = str.gsub(/\s*/, '')
        string.length > 1 && !%w(&nbsp;).include?(string)
      end

      def load_corrector
        corrector_name = @config['corrector'].fetch('name') { raise MissingCorrector }
        raise ForbiddenCorrector unless ALLOWED_CORRECTORS.include?(corrector_name)
        require @config['corrector'].fetch('path') { raise MissingCorrector }

        corrector_name.safe_constantize
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
        elsif inner_node.type == :erb
          inner_node.loc.source
        else
          false
        end
      end

      def message(string)
        stripped_string = string.strip

        "String not translated: #{stripped_string}"
      end
    end
  end
end
