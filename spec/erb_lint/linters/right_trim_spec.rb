# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::RightTrim do
  let(:linter_config) { described_class.config_schema.new(enforced_style: enforced_style) }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses(processed_source) }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }

  describe 'offenses' do
    subject { offenses }

    context 'when enforced_style is -' do
      let(:enforced_style) { '-' }

      context 'when trim is correct' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to eq [] }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo =%>" }
        it do
          expect(subject).to eq [
            build_offense(7..7, "Prefer -%> instead of =%> for trimming on the right.")
          ]
        end
      end
    end

    context 'when enforced_style is =' do
      let(:enforced_style) { '=' }

      context 'when trim is correct' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to eq [] }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo -%>" }
        it do
          expect(subject).to eq [
            build_offense(7..7, "Prefer =%> instead of -%> for trimming on the right.")
          ]
        end
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when enforced_style is -' do
      let(:enforced_style) { '-' }

      context 'when trim is correct' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to eq file }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to eq "<% foo -%>" }
      end
    end

    context 'when enforced_style is =' do
      let(:enforced_style) { '=' }

      context 'when trim is correct' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to eq file }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to eq "<% foo =%>" }
      end
    end
  end

  private

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range.begin, range.end),
      message
    )
  end
end
