# frozen_string_literal: true

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

    # Must be implemented by the concrete inheriting class.
    def initialize(_config)
      raise NotImplementedError, "must implement ##{__method__}"
    end

    # The lint_file method that contains the logic for the linter and returns a list of errors.
    # Must be implemented by the concrete inheriting class.
    def lint_file(_file_tree)
      raise NotImplementedError, "must implement ##{__method__}"
    end
  end
end
