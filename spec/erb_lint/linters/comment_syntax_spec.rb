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

  context "when the ERB multi-line comment syntax is correct" do
    let(:file) { <<~FILE }
      <%
        # good comment
      %>
    FILE

    it "does not report any offenses" do
      expect(subject.size).to(eq(0))
    end
  end

  context "when the ERB comment syntax is incorrect" do
    let(:file) { <<~FILE }
      <% # bad comment %>
    FILE

    it "reports one offense" do
      expect(subject.size).to(eq(1))
    end

    it "reports the suggested fix" do
      expect(subject.first.message).to(include("Bad ERB comment syntax. Should be <%# without a space between."))
    end
  end

  context "when the ERB comment syntax is incorrect multiple times in one file" do
    let(:file) { <<~FILE }
      <% # first bad comment %>
      <%= # second bad comment %>
      <%- # third bad comment %>
    FILE

    it "reports all offenses" do
      expect(subject.size).to(eq(file.each_line.count))
    end

    it "reports the suggested fixes" do
      expected_messages = [
        "Bad ERB comment syntax. Should be <%# without a space between.",
        "Bad ERB comment syntax. Should be <%#= or <%# without a space between.",
        "Bad ERB comment syntax. Should be <%-# without a space between.",
      ]
      actual_messages = subject.map(&:message)
      expect(actual_messages.size).to(eq(expected_messages.size))

      expected_messages.zip(actual_messages).each do |expected, actual|
        expect(actual).to(include(expected))
      end
    end
  end
end
