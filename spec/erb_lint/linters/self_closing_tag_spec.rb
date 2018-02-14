# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::SelfClosingTag do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  before { linter.run(processed_source) }

  describe 'offenses' do
    subject { offenses }

    context 'when an element is not self-closing' do
      let(:file) { "<a></a/>" }
      it { expect(subject).to eq [] }
    end

    context 'when an element is self-closed correctly' do
      let(:file) { "<br/>" }
      it { expect(subject).to eq [] }
    end

    context 'when an element is not #self_closing?' do
      let(:file) { "<br>" }
      it do
        expect(subject).to eq [
          build_offense(3..2, "Tag `br` is self-closing, it must end with `/>`.")
        ]
      end
    end

    context 'when an element is #closing? and #self_closing?' do
      let(:file) { "</br/>" }
      it do
        expect(subject).to eq [
          build_offense(1..1, "Tag `br` is self-closing, it must not start with `</`.")
        ]
      end
    end

    context 'when an element is #closing?' do
      let(:file) { "</br>" }
      it do
        expect(subject).to eq [
          build_offense(1..1, "Tag `br` is self-closing, it must not start with `</`."),
          build_offense(4..3, "Tag `br` is self-closing, it must end with `/>`.")
        ]
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when an element is not self-closing' do
      let(:file) { "<a></a/>" }
      it { expect(subject).to eq file }
    end

    context 'when an element is self-closed correctly' do
      let(:file) { "<br/>" }
      it { expect(subject).to eq file }
    end

    context 'when an element is not #self_closing?' do
      let(:file) { "<br>" }
      it { expect(subject).to eq "<br/>" }
    end

    context 'when an element is #closing? and #self_closing?' do
      let(:file) { "</br/>" }
      it { expect(subject).to eq "<br/>" }
    end

    context 'when an element is #closing?' do
      let(:file) { "</br>" }
      it { expect(subject).to eq "<br/>" }
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
