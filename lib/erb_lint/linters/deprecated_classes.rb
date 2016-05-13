module ERBLint
  # Checks for deprecated classes in the start tags of HTML elements.
  class Linter::DeprecatedClasses < Linter
    include LinterRegistry

    def initialize(config)
      @deprecated_ruleset = []
      config['rule_set'].each do |rule|
        rule['deprecated'].each do |class_expr|
          @deprecated_ruleset.push {
            class_expr: class_expr,
            suggestion: rule['suggestion']
          }
        end
      end
      @deprecated_ruleset.freeze

      @addendum = config['addendum']
    end

    def lint_lines(lines)
      errors = []

      lines.each_with_index do |line, index|
        # p "Line #{index + 1}: #{line}"
        start_tags = StartTagHelper.start_tags(line)
        # p start_tags
        start_tags.each do |start_tag|
          start_tag.attributes.select(&:is_class?).each do |class_attr|
            class_attr.value.split(' ').each do |class_name|
              violated_rules(class_name).each do |violated_rule|
                errors.push {
                  line: index + 1,
                  message: "Deprecated class `#{class_name}` detected matching the pattern `#{violated_rule[:class_expr]}`. #{violated_rule[:suggestion]} #{@addendum}"
                }
              end
            end
          end
        end
      errors
    end

    private

    def violated_rules(class_name)
      @deprecated_ruleset.select do |deprecated_rule|
        /\A#{deprecated_rule[:class_expr]}\z/.match(class_name)
      end
    end
  end

  module StartTagHelper
    # These patterns cover a superset of the W3 HTML5 specification. Additional cases not included in the spec include those that are still rendered by some browsers.
    # https://www.w3.org/TR/html5/syntax.html#attributes
    @@attribute_name = /[^\s"'>\/=]+/ # attribute names must be non empty and can't have a certain set of special characters
    @@attribute_value = /"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)/ # attribute values can be double-quoted OR single-quoted OR unquoted
    @@attribute_pattern = /#{@@attribute_name}(\s*=\s*(#{@@attribute_value}))?/ # attributes can be empty or have an attribute value

    # https://www.w3.org/TR/html5/syntax.html#syntax-start-tag
    @@tag_name_pattern = /[A-Za-z0-9]+/ # maybe add _ < ? etc later since it gets interpreted by some browsers
    @@start_tag_pattern = /<(#{@@tag_name_pattern})(\s+(#{@@attribute_pattern}\s*)*)?\/?>/ # start tag must have a space after tag name if attributes exist. /> or > to end the tag.


    def start_tags(line)
      start_tag_matching_groups = line.scan(/(#{@@start_tag_pattern})/)
      start_tag_matching_groups.map do |start_tag_matching_group| 
        tag_name = start_tag_matching_group[1]
        attributes_string = start_tag_matching_group[2] 

        attributes = attributes_string.scan(/(#{@@attribute_pattern})/).map do |attribute_matching_group|
          entire_string = attribute_matching_group[0]
          value_with_equal_sign = attribute_matching_group[1]
          name = entire_string.sub(value_with_equal_sign, '')
          possible_value_formats = attribute_matching_group[3..5] # These 3 captures are the ones in @@attribute_value
          value = possible_value_formats.reduce {|a, b| a.nil? ? b : a}
          Attribute.new(name, value)
        end

        StartTag.new(tag_name, attributes)
      end
    end

    class StartTag
      attr_accessor :tag_name, :attributes

      def initialize(tag_name, attributes)
        @tag_name = tag_name
        @attributes = attributes 
      end 
    end

    class Attribute
      @@class_attr_name_pattern = /\Aclass\z/i #attribute names are case-insensitive
      attr_accessor :attribute_name, :value

      def initialize(attribute_name, value)
        @attribute_name = attribute_name 
        @value = value 
      end 

      def is_class?
        @@class_attr_name_pattern.match(@attribute_name)
      end
    end
  end
end
