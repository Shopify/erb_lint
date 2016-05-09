module ERBLint
  # Stores all linters available to the application.
  module LinterRegistry
    CUSTOM_LINTERS_DIR = '.erb-linters'
    @linters = []

    class << self
      attr_reader :linters

      def included(custom_linter_class)
        @linters << custom_linter_class
      end

      def load_linters
        ruby_files = Dir.glob(File.expand_path(File.join(CUSTOM_LINTERS_DIR, '**', '*.rb')))
        ruby_files.each { |file| require file }
      end
    end
  end
end