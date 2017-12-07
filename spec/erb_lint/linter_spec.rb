# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter do
  context 'when inheriting from the Linter class' do
    let(:linter_config) { {} }
    let(:file_loader)   { ERBLint::FileLoader.new('.') }
    subject             { ERBLint::Linters::Fake.new(file_loader, linter_config) }

    module ERBLint
      module Linters
        class Fake < ERBLint::Linter
          protected

          def lint_lines(_lines)
          end
        end
      end
    end

    describe '#lint_file' do
      after do
        subject.lint_file(file)
      end

      context 'when the file is empty' do
        let(:file) { '' }

        it 'calls lint_lines with an empty list' do
          expect(subject).to receive(:lint_lines).with([])
        end
      end

      context 'when the file does not end with a newline' do
        let(:file) { <<~FILE.chomp }
          Line1
          Line2
          Line3
        FILE

        it 'calls lint_lines with the list of lines' do
          expect(subject).to receive(:lint_lines).with(%W(
            Line1\n
            Line2\n
            Line3
          ))
        end
      end

      context 'when the file ends with a newline' do
        let(:file) { <<~FILE }
          Line1
          Line2
          Line3
        FILE

        it 'calls lint_lines with the list of lines' do
          expect(subject).to receive(:lint_lines).with(%W(
            Line1\n
            Line2\n
            Line3\n
          ))
        end
      end
    end

    describe '.simple_name' do
      it 'returns the name of the class with the ERBLint::Linter prefix removed' do
        expect(subject.class.simple_name).to eq 'Fake'
      end
    end
  end
end
