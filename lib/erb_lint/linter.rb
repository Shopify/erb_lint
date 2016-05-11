module ERBLint
  # Defines common functionality available to all linters.
  class Linter
    class << self
      attr_accessor :simple_name

      # When defining a Linter class, define its simple name as well. This
      # assumes that the module hierarchy of every linter starts with
      # `ERBLint::Linter::`, and removes this part of the class name.
      #
      # `ERBLint::Linter::Foo.simple_name`          #=> "Foo"
      # `ERBLint::Linter::Compass::Bar.simple_name` #=> "Compass::Bar"
      def inherited(linter)
        name_parts = linter.name.split('::')
        name = name_parts.length < 3 ? '' : name_parts[2..-1].join('::')
        linter.simple_name = name
      end
    end

    # The lint method that contains the logic for linter and returns a list of errors.
    # Must be implemented by the concrete inheriting class.
    def self.lint(_file_content)
      raise NotImplementedError, "must implement ##{__method__}"
    end
  end
end