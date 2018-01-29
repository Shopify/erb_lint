# frozen_string_literal: true

module ERBLint
  module Linters
    # Detects extra or missing whitespace in html tags.
    class SpaceInHtmlTag < Linter
      include LinterRegistry

      def offenses(processed_source)
        offenses = []
        processed_source.ast.descendants(:tag).each do |tag_node|
          start_solidus, name, attributes, end_solidus = *tag_node

          next_loc = name&.loc&.start || attributes&.loc&.start ||
            end_solidus&.loc&.start || tag_node.loc.stop
          if start_solidus
            offenses << no_space(processed_source, tag_node.loc.start + 1, start_solidus.loc.start)
            offenses << no_space(processed_source, start_solidus.loc.stop + 1, next_loc)
          else
            offenses << no_space(processed_source, tag_node.loc.start + 1, next_loc)
          end

          if attributes
            offenses << single_space_or_newline(processed_source, name.loc.stop + 1, attributes.loc.start) if name
            offenses.concat(process_attributes(processed_source, attributes) || [])
          end

          previous_loc = attributes&.loc&.stop || name&.loc&.stop ||
            start_solidus&.loc&.stop || tag_node.loc.start
          if end_solidus
            offenses << single_space(processed_source, previous_loc + 1, end_solidus.loc.start)
            offenses << no_space(processed_source, end_solidus.loc.stop + 1, tag_node.loc.stop)
          else
            offenses << no_space(processed_source, previous_loc + 1, tag_node.loc.stop)
          end
        end
        offenses.compact
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context)
        end
      end

      private

      def no_space(processed_source, begin_pos, end_pos)
        range = Range.new(begin_pos, end_pos - 1)
        chars = processed_source.file_content[range]
        return if chars.empty?

        Offense.new(
          self,
          processed_source.to_source_range(begin_pos, end_pos - 1),
          "Extra space detected where there should be no space.",
          ''
        )
      end

      def single_space_or_newline(processed_source, begin_pos, end_pos)
        single_space(processed_source, begin_pos, end_pos, accept_newline: true)
      end

      def single_space(processed_source, begin_pos, end_pos, accept_newline: false)
        range = Range.new(begin_pos, end_pos - 1)
        chars = processed_source.file_content[range]
        return if chars == ' '

        newlines = chars.include?("\n")
        expected = newlines && accept_newline ? "\n#{chars.split("\n", -1).last}" : ' '
        non_space = chars.match(/([^[[:space:]]])/m)

        if non_space && !non_space.captures.empty?
          Offense.new(
            self,
            processed_source.to_source_range(begin_pos, end_pos - 1),
            "Non-whitespace character(s) detected: "\
              "#{non_space.captures.map(&:inspect).join(', ')}.",
            expected
          )
        elsif newlines && accept_newline
          if expected != chars
            Offense.new(
              self,
              processed_source.to_source_range(begin_pos, end_pos - 1),
              "#{chars.empty? ? 'No' : 'Extra'} space detected where there should be "\
                "a single space or a single line break.",
              expected
            )
          end
        else
          Offense.new(
            self,
            processed_source.to_source_range(begin_pos, end_pos - 1),
            "#{chars.empty? ? 'No' : 'Extra'} space detected where there should be a single space.",
            expected
          )
        end
      end

      def process_attributes(processed_source, attributes)
        offenses = []
        attributes.children.each_with_index do |attribute, index|
          name, equal, value = *attribute
          offenses << no_space(processed_source, name.loc.stop + 1, equal.loc.start) if equal
          offenses << no_space(processed_source, equal.loc.stop + 1, value.loc.start) if equal && value

          next if index >= attributes.children.size - 1
          next_attribute = attributes.children[index + 1]

          offenses << single_space_or_newline(processed_source,
            attribute.loc.stop + 1, next_attribute.loc.start)
        end
        offenses
      end
    end
  end
end
