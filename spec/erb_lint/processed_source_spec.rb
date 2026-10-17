# frozen_string_literal: true

require "spec_helper"

describe ERBLint::ProcessedSource do
  describe "#to_source_range" do
    it "converts RuboCop offenses without a source location" do
      processed_source = described_class.new("file.erb", "<% value %>")

      source_range = processed_source.to_source_range(RuboCop::Cop::Offense::NO_LOCATION)

      expect(source_range.begin_pos).to(eq(0))
      expect(source_range.end_pos).to(eq(0))
    end
  end
end
