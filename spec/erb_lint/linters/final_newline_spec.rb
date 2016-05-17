require 'spec_helper'

describe ERBLint::Linter::FinalNewline do
  let(:linter_config) { { 'present' => present } }

  let(:linter) { described_class.new(linter_config) }
  
  subject(:linter_errors) { linter.lint_file(file) }

  context 'when trailing newline is preferred' do
    let(:present) { true }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'should report 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'should report an error on the last line' do
        expect(linter_errors.first[:line]).to eq 3
      end
    end
  end

  context 'when no trailing newline is preferred' do
    let(:present) { false }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'should report 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'should report an error on the last line' do
        expect(linter_errors.first[:line]).to eq 3
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end
  end

  context 'when trailing newline preference is not stated' do
    let(:linter_config) { {} }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'should report 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'should report an error on the last line' do
        expect(linter_errors.first[:line]).to eq 3
      end
    end
  end
end