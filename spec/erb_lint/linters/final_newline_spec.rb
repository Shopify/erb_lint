# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::FinalNewline do
  let(:linter_config) { described_class.config_schema.new(present: present) }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new(file) }
  subject(:offenses) { linter.offenses(processed_source) }

  context 'when trailing newline is preferred' do
    let(:present) { true }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'does not report any errors' do
        expect(subject).to eq []
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'reports 1 offense' do
        expect(subject.size).to eq 1
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to eq 3..3
      end
    end
  end

  context 'when no trailing newline is preferred' do
    let(:present) { false }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'reports 1 offense' do
        expect(subject.size).to eq 1
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to eq 3..3
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'does not report any offenses' do
        expect(subject).to eq []
      end
    end
  end

  context 'when trailing newline preference is not stated' do
    let(:linter_config) { described_class.config_schema.new }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'does not report any offenses' do
        expect(subject).to eq []
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'reports 1 offense' do
        expect(subject.size).to eq 1
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to eq 3..3
      end
    end
  end
end
