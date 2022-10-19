# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::CommentSyntax do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }

  subject { linter.offenses }
  before { linter.run(processed_source) }

  context "when the ERB comment syntax is correct" do
    let(:file) { <<~FILE }
      <%# good comment %>
    FILE

    it "does not report any offenses" do
      expect(subject.size).to(eq(0))
    end
  end

  context "when the ERB comment syntax is incorrect" do
    let(:file) { <<~FILE }
      <% # first bad comment %>
      <%= # second bad comment %>
    FILE

    it "reports two offenses" do
      expect(subject.size).to(eq(2))
    end

    it "reports two offenses with their suggested fixes" do
      expect(subject.first.message).to(include("Bad ERB comment syntax. Should be `<%#=` without a space between."))
      expect(subject.last.message).to(include("Bad ERB comment syntax. Should be `<%#` without a space between."))
    end
  end
end
