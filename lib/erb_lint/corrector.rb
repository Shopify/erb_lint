# frozen_string_literal: true

module ERBLint
  class Corrector
    attr_reader :processed_source, :offenses, :corrected_content

    def initialize(processed_source, offenses)
      @processed_source = processed_source
      @offenses = offenses
      @corrected_content = corrector.rewrite

      raise corrector.diagnostics.join(', ') if corrector.diagnostics.any?
    end

    def corrections
      @corrections ||= @offenses.map do |offense|
        offense.linter.autocorrect(@processed_source, offense)
      end.compact
    end

    def corrector
      @corrector ||= RuboCop::Cop::Corrector.new(processed_source.source_buffer, corrections)
    end

    def update_offenses
      @offenses.each do |offense|
        offense.status = :corrected
      end
    end

    def diagnostics
      corrector.diagnostics
    end

    def write
      unless processed_source.file_content == corrected_content
        File.open(processed_source.filename, "wb") do |file|
          file.write(corrected_content)
        end
      end
    end
  end
end
