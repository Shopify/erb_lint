# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::PartialInstanceVariable do
  let(:linter_config) { described_class.config_schema.new }
  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source_one) { ERBLint::ProcessedSource.new("_file.html.erb", file) }
  let(:processed_source_two) { ERBLint::ProcessedSource.new("app/views/_a_model/a_view.html.erb", file) }
  let(:processed_source_three) { ERBLint::ProcessedSource.new("_variant.html+mobile.erb", file) }
  let(:offenses) { linter.offenses }
  before do
    linter.run(processed_source_one)
    linter.run(processed_source_two)
    linter.run(processed_source_three)
  end

  describe "offenses" do
    subject { offenses }

    context "when instance variable is not present" do
      let(:file) { "<%= user.first_name %>" }
      it { expect(subject).to(eq([])) }
    end

    context "when instance variable is present" do
      let(:file) { "<h2><%= @user.first_name %></h2>" }
      it do
        expect(subject).to(eq([
          build_offense(processed_source_one, 7..32, "Instance variable detected in partial."),
          build_offense(processed_source_three, 7..32, "Instance variable detected in partial."),
        ]))
      end
    end
  end

  private

  def build_offense(processed_source, range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message,
    )
  end
end
