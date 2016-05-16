module ERBLint
  # Checks for final newlines at the end of a file.
  class Linter::FinalNewline < Linter
    include LinterRegistry

    def initialize(config)
      @new_lines_should_be_present = config['present']
    end

    protected

    def lint_lines(lines)
      errors = []
      return errors if lines.empty?

      ends_with_newline = lines.last.chars[-1] == "\n"

      if @new_lines_should_be_present && !ends_with_newline
        errors.push({
          line: lines.length,
          message: "Missing a trailing newline at the end of the file."
        })
      elsif !@new_lines_should_be_present && ends_with_newline
        errors.push({
          line: lines.length,
          message: "Remove the trailing newline at the end of the file."
        })
      end
      errors
    end
  end
end
