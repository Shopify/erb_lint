# frozen_string_literal: true

require 'json'

module ERBLint
  class Stats
    attr_reader :files, :inspected_file_count

    def initialize
      @corrected = 0
      @inspected_file_count = 0
      @files = []
    end

    def remaining_errors
      offense_count - corrected
    end

    def corrected
      @files.map { |off| off[:offenses] }.flatten.count(&:corrected?)
    end

    def offense_count
      @files.map { |off| off[:offenses] }.flatten.size
    end

    def add_offending_file(file, offenses)
      if offenses.any?
        offending_file = @files.find { |off| off[:path] == file }
        if offending_file
          offending_file[:offenses] += offenses
        else
          @inspected_file_count += 1
          @files << { path: file, offenses: offenses }
        end
      end
    end

    def metadata
      @metadata ||= {
        erb_lint_version: ERBLint::VERSION,
        ruby_engine: RUBY_ENGINE,
        ruby_version: RUBY_VERSION,
        ruby_patchlevel: RUBY_PATCHLEVEL.to_s,
        ruby_platform: RUBY_PLATFORM,
      }
    end

    def to_json(*options)
      to_h.to_json(*options)
    end

    def to_h
      {
        metadata: metadata,
        summary: { inspected_file_count: inspected_file_count,
                   offense_count: offense_count,
                   corrected: corrected,
                   remaining_errors: remaining_errors },
        files: @files.dup.each { |off| off[:offenses] = off[:offenses].map(&:to_h) },
      }
    end
  end
end
