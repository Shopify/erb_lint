# frozen_string_literal: true

module SpecUtils
  def self.source_range_for_code(processed_source, code)
    offending_source = processed_source.file_content.match(code)
    processed_source.to_source_range(offending_source.begin(0)...offending_source.end(0))
  end
end
