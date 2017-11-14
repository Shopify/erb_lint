# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Linter
    class << self
      attr_accessor :simple_name

      # When defining a Linter class, define its simple name as well. This
      # assumes that the module hierarchy of every linter starts with
      # `ERBLint::Linters::`, and removes this part of the class name.
      #
      # `ERBLint::Linters::Foo.simple_name`          #=> "Foo"
      # `ERBLint::Linters::Compass::Bar.simple_name` #=> "Compass::Bar"
      def inherited(linter)
        name_parts = linter.name.split('::')
        name = name_parts.length < 3 ? '' : name_parts[2..-1].join('::')
        linter.simple_name = name
      end
    end

    # Must be implemented by the concrete inheriting class.
    def initialize(file_loader, _config)
      @file_loader = file_loader
    end

    def lint_file(file_content)
      lines = file_content.scan(/[^\n]*\n|[^\n]+/)
      lint_lines(lines)
    end

    protected

    # The lint_lines method that contains the logic for the linter and returns a list of errors.
    # Must be implemented by the concrete inheriting class.
    def lint_lines(_lines)
      raise NotImplementedError, "must implement ##{__method__}"
    end
  end
end
