require 'spec_helper'

describe ERBLint::Linter::DeprecatedClasses do
  let(:linter_config) do
    { 
      'rule_set' => rule_set
    }
  end

  let(:linter) { described_class.new(linter_config) }
  
  subject(:linter_errors) { linter.lint_file(file) }

  context 'when the rule set is empty' do
    let(:rule_set) { [] }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file has classes in tags' do
      let(:file) { "<div class=\"a\">\nContent\n</div>" }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end
  end

  context 'when the rule set has deprecated classes' do
    deprecated_set_1 = ['abc', 'foo-bar--darker']
    suggestion_1 = 'Suggestion1'
    deprecated_set_2 = ['expr', 'expr[\w-]*']
    suggestion_2 = 'Suggestion2'

    let(:rule_set) do
      [{
        'deprecated' => deprecated_set_1,
        'suggestion' => suggestion_1
      },
      {
        'deprecated' => deprecated_set_2,
        'suggestion' => suggestion_2
      }]
    end

    context 'when the file is empty' do
      let(:file) { '' }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file contains no classes from either set' do
      let(:file) { "<div class=\"unknown\">\nContent\n</div>" }

      it 'should not report any errors' do
        expect(linter_errors).to eq []
      end
    end

    context 'when the file contains a class from set 1' do
      let(:file) { "<div class=\"#{deprecated_set_1.first}\">\nContent\n</div>" }

      it 'should report 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'should report an error with message containing suggestion 1' do
        expect(linter_errors.first[:message]).to include suggestion_1
      end
    end

    context 'when the file contains both classes from set 1' do
      context 'when both classes are on the same tag' do
        let(:file) { "<div class=\"#{deprecated_set_1[0]} #{deprecated_set_1[1]}\">\nContent\n</div>" }

        it 'should report 2 errors' do
          expect(linter_errors.size).to eq 2
        end

        it 'should report errors with messages containing suggestion 1' do
          expect(linter_errors[0][:message]).to include suggestion_1
          expect(linter_errors[1][:message]).to include suggestion_1
        end

      end

      context 'when both classes are on different tags' do
        let(:file) { "<div class=\"#{deprecated_set_1[0]}\">\n<a href=\"#\" class=\"#{deprecated_set_1[1]}\"></a>\n</div>" }

        it 'should report 2 errors' do
          expect(linter_errors.size).to eq 2
        end

        it 'should report errors with messages containing suggestion 1' do
          expect(linter_errors[0][:message]).to include suggestion_1
          expect(linter_errors[1][:message]).to include suggestion_1
        end
      end
    end

    context 'when the file contains a class matching both expressions from set 2' do
      let(:file) { "<div class=\"expr\">\nContent\n</div>" }

      it 'should report 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'should report errors with messages containing suggestion 2' do
        expect(linter_errors[0][:message]).to include suggestion_2
        expect(linter_errors[1][:message]).to include suggestion_2
      end
    end

    context 'when an addendum is present' do
      let(:linter_config) do
        {
          'rule_set' => rule_set,
          'addendum' => addendum
        }
      end
      let(:addendum) { 'Addendum badoo ba!' }

      context 'when the file is empty' do
        let(:file) { '' }

        it 'should not report any errors' do
          expect(linter_errors).to eq []
        end
      end

      context 'when the file contains a class from a deprecated set' do
      let(:file) { "<div class=\"#{deprecated_set_1.first}\">\nContent\n</div>" }

        it 'should report 1 error' do
          expect(linter_errors.size).to eq 1
        end

        it 'should report an error with its message ending with the addendum' do
          expect(linter_errors.first[:message]).to end_with addendum
        end
      end
    end

    context 'when an addendum is absent' do
      let(:linter_config) do
        {
          'rule_set' => rule_set
        }
      end

      context 'when the file is empty' do
        let(:file) { '' }

        it 'should not report any errors' do
          expect(linter_errors).to eq []
        end
      end

      context 'when the file contains a class from a deprecated set' do
      let(:file) { "<div class=\"#{deprecated_set_1.first}\">\nContent\n</div>" }

        it 'should report 1 error' do
          expect(linter_errors.size).to eq 1
        end

        it 'should report an error with its message ending with the suggestion' do
          expect(linter_errors.first[:message]).to end_with suggestion_1
        end
      end
    end
  end
end