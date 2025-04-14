# frozen_string_literal: true

require "spec_helper"
require "spec_utils"

describe ERBLint::Linters::NoUnusedDisable do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }
  let(:offenses) { linter.offenses }

  module ERBLint
    module Linters
      class Fake < ERBLint::Linter
        attr_accessor :offenses
      end
    end
  end

  describe "offenses" do
    subject { offenses }
    context "when file has unused disable comment" do
      let(:file) { "<span></span><%# erblint:disable Fake %>" }
      before { linter.run(processed_source, []) }
      it do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(eq("Unused erblint:disable comment for Fake"))
      end
    end

    context "when file has a disable comment and a corresponding offense" do
      let(:file) { "<span></span><%# erblint:disable Fake %>" }
      before do
        offense = ERBLint::Offense.new(
          ERBLint::Linters::Fake.new(file_loader, linter_config),
          SpecUtils.source_range_for_code(processed_source, "<span></span>"),
          "some fake linter message",
        )
        offense.disabled = true
        linter.run(processed_source, [offense])
      end

      it "does not report anything" do
        expect(subject.size).to(eq(0))
      end
    end

    context "when file has a disable comment in wrong place and a corresponding offense" do
      let(:file) { <<~FILE }
        <%# erblint:disable Fake %>
        <span>bad content</span>
      FILE
      before do
        offense = ERBLint::Offense.new(
          ERBLint::Linters::Fake.new(file_loader, linter_config),
          SpecUtils.source_range_for_code(processed_source, "<span>bad content</span>"),
          "some fake linter message",
        )
        offense.disabled = true
        linter.run(processed_source, [offense])
      end

      it "reports the unused inline comment" do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(eq("Unused erblint:disable comment for Fake"))
      end
    end

    context "when file has disable comment for multiple rules" do
      let(:file) { "<span></span><%# erblint:disable Fake, Fake2 %>" }
      before do
        offense = ERBLint::Offense.new(
          ERBLint::Linters::Fake.new(file_loader, linter_config),
          SpecUtils.source_range_for_code(processed_source, "<span></span>"),
          "some fake linter message",
        )
        offense.disabled = true
        linter.run(processed_source, [offense])
      end

      it "reports the unused inline comment" do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(eq("Unused erblint:disable comment for Fake2"))
      end
    end

    context "when file has multiple disable comments for one offense" do
      let(:file) { <<~ERB }
        <%# erblint:disable Fake %>
        <span></span><%# erblint:disable Fake %>
      ERB
      before do
        offense = ERBLint::Offense.new(
          ERBLint::Linters::Fake.new(file_loader, linter_config),
          SpecUtils.source_range_for_code(processed_source, "<span></span>"),
          "some fake linter message",
        )
        offense.disabled = true
        linter.run(processed_source, [offense])
      end

      it "reports the unused inline comment" do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(eq("Unused erblint:disable comment for Fake"))
      end
    end
  end
end
