# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::PartialInstanceVariable do
  let(:linter_config) { described_class.config_schema.new }
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('_file.html.erb', file) }
  let(:offenses) { linter.offenses }
  before { linter.run(processed_source) }

  describe 'offenses' do
    subject { offenses }

    context 'when instance varaible is not present' do
      let(:file) { "<%= user.first_name %>" }
      it { expect(subject).to(eq([])) }
    end

    context 'when instance variable is present' do
      let(:file) { "<h2><%= @user.first_name %></h2>" }
      it do
        expect(subject).to(eq([
          build_offense(7..32, "Instance variable detected in partial."),
        ]))
      end
    end
  end

  private

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message
    )
  end
end
