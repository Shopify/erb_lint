# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter do
  context 'when inheriting from the Linter class' do
    let(:linter_config) { {} }
    subject             { ERBLint::Linter::Fake.new(linter_config) }

    module ERBLint
      class Linter
        class Fake < ERBLint::Linter
          def initialize(_config)
          end

          def lint_file(_file_tree)
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
