# frozen_string_literal: true

module ERBLint
  class Linter
    # Checks for deprecated classes in the start tags of HTML elements.
    class DeprecatedClasses < Linter
      include LinterRegistry

      def initialize(config)
        @deprecated_ruleset = []
        config['rule_set'].each do |rule|
          rule['deprecated'].each do |class_expr|
            @deprecated_ruleset.push(
              class_expr: class_expr,
              suggestion: rule['suggestion']
            )
          end
        end
        @deprecated_ruleset.freeze

        @addendum = config['addendum']
      end

      protected

      def lint_lines(lines)
        errors = []

        lines.each_with_index do |line, index|
          start_tags = StartTagHelper.start_tags(line)
          start_tags.each do |start_tag|
            start_tag.attributes.select(&:class?).each do |class_attr|
              class_attr.value.split(' ').each do |class_name|
                errors.push(*generate_errors(class_name, index + 1))
              end
            end
          end
        end
        errors
      end

      private

      def generate_errors(class_name, line_number)
        violated_rules(class_name).map do |violated_rule|
          message = "Deprecated class `%s` detected matching the pattern `%s`. %s#{' ' + @addendum if @addendum}"
          {
            line: line_number,
            message: format(message, class_name, violated_rule[:class_expr], violated_rule[:suggestion])
          }
        end
      end

      def violated_rules(class_name)
        @deprecated_ruleset.select do |deprecated_rule|
          /\A#{deprecated_rule[:class_expr]}\z/.match(class_name)
        end
      end
    end

    # Provides methods and classes for finding HTML start tags and their attributes.
    module StartTagHelper
      # These patterns cover a superset of the W3 HTML5 specification.
      # Additional cases not included in the spec include those that are still rendered by some browsers.

      # Attribute Patterns
      # https://www.w3.org/TR/html5/syntax.html#syntax-attributes

      # attribute names must be non empty and can't contain a certain set of special characters
      ATTRIBUTE_NAME_PATTERN = %r{[^\s"'>\/=]+}

      ATTRIBUTE_VALUE_PATTERN = %r{
        "([^"]*)" |           # double-quoted value
        '([^']*)' |           # single-quoted value
        ([^\s"'=<>`]+)        # unquoted non-empty value without special characters
      }x

      # attributes can be empty or have an attribute value
      ATTRIBUTE_PATTERN = %r{
        #{ATTRIBUTE_NAME_PATTERN}        # attribute name
        (
          \s*=\s*                 # any whitespace around equals sign
          (#{ATTRIBUTE_VALUE_PATTERN})   # attribute value
        )?                        # attributes can be empty or have an assignemnt.
      }x

      # Start tag Patterns
      # https://www.w3.org/TR/html5/syntax.html#syntax-start-tag

      TAG_NAME_PATTERN = /[A-Za-z0-9]+/ # maybe add _ < ? etc later since it gets interpreted by some browsers

      START_TAG_PATTERN = %r{
        <(#{TAG_NAME_PATTERN})         # start of tag with tag name
        (
          \s+                           # required whitespace between tag name and attributes
          (#{ATTRIBUTE_PATTERN}\s*)*   # attributes
        )?                              # having attributes is optional
        \/?>                            # void or foreign element can have slash before tag close
      }x

      # Represents and provides an interface for a start tag found in the HTML.
      class StartTag
        attr_accessor :tag_name, :attributes

        def initialize(tag_name, attributes)
          @tag_name = tag_name
          @attributes = attributes
        end
      end

      # Represents and provides an interface for an attribute found in a start tag in the HTML.
      class Attribute
        ATTR_NAME_CLASS_PATTERN = /\Aclass\z/i # attribute names are case-insensitive
        attr_accessor :attribute_name, :value

        def initialize(attribute_name, value)
          @attribute_name = attribute_name
          @value = value
        end

        def class?
          ATTR_NAME_CLASS_PATTERN.match(@attribute_name)
        end
      end

      class << self
        def start_tags(line)
          # TODO: Implement String Scanner to track quotes before the start tag begins to ensure that it is
          #       not enclosed inside of a string. Alternatively this problem would be solved by using
          #       a 3rd party parser like Nokogiri::XML

          start_tag_matching_groups = line.scan(/(#{START_TAG_PATTERN})/)
          start_tag_matching_groups.map do |start_tag_matching_group|
            tag_name = start_tag_matching_group[1]

            # attributes_string can be nil if there is no space after the tag name (and therefore no attributes).
            attributes_string = start_tag_matching_group[2] || ''

            attribute_list = attributes(attributes_string)

            StartTag.new(tag_name, attribute_list)
          end
        end

        private

        def attributes(attributes_string)
          attributes_string.scan(/(#{ATTRIBUTE_PATTERN})/).map do |attribute_matching_group|
            entire_string = attribute_matching_group[0]
            value_with_equal_sign = attribute_matching_group[1] || '' # This can be nil if attribute is empty
            name = entire_string.sub(value_with_equal_sign, '')

            # The 3 captures [3..5] are the possibilities specified in ATTRIBUTE_VALUE_PATTERN
            possible_value_formats = attribute_matching_group[3..5]
            value = possible_value_formats.reduce { |a, e| a.nil? ? e : a }

            Attribute.new(name, value)
          end
        end
      end
    end
  end
end
