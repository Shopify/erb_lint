# frozen_string_literal: true

module ERBLint
  module Utils
    class FileUtils
      def self.relative_filename(filename)
        filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
      end
    end
  end
end
