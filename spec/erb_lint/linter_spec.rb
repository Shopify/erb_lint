# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter do
  context 'when inheriting from the Linter class' do
    let(:linter_config) { ERBLint::LinterConfig.new }
    let(:file_loader)   { ERBLint::FileLoader.new('.') }
    let(:linter) { ERBLint::Linters::Fake.new(file_loader, linter_config) }
    let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
    subject { linter }

    module ERBLint
      module Linters
        class Fake < ERBLint::Linter
          def offenses(_processed_source)
          end
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
