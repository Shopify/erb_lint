# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linter::ContentStyle do
  let(:linter_config) do
    {
      'rule_set' => rule_set,
      'addendum' => 'Questions? Contact Lintercorp Product Content at product-content@lintercorp.com.'
    }
  end

  let(:linter) { described_class.new(linter_config) }

  subject(:linter_errors) { linter.lint_file(ERBLint::Parser.parse(file)) }

  context 'when rule set is empty' do
    let(:rule_set) { [] }

    context 'when file is empty' do
      let(:file) { '' }

      it 'does not report any errors' do
        expect(linter_errors).to eq []
      end
    end
  end

  context 'when rule set and file contain violations' do
    context 'when rule is case-insensitive and file contains violations in different cases' do
      violation_set_1 = ['dropdown', 'drop down']
      suggestion_1 = 'drop-down'
      case_insensitive_1 = true

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'case_insensitive' => case_insensitive_1
          }
        ]
      end

      let(:file) { <<~FILE }
        <p>Tune in, turn on, and drop-down out! And check out the Drop down and dropdown menu too.</p>

      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'reports errors for `Drop down` and `dropdown` and suggests `drop-down`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `dropdown`'
        expect(linter_errors[0][:message]).to include 'Do use `drop-down`'
        expect(linter_errors[1][:message]).to include 'Don\'t use `drop down`'
        expect(linter_errors[1][:message]).to include 'Do use `drop-down`'
      end
    end

    context 'when suggestion is prefix + violation' do
      violation_set_1 = ['Help Center', 'help center']
      suggestion_1 = 'Lintercorp Help Center'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end

      let(:file) { <<~FILE }
        <p>Help! I need a Lintercorp Help Center. Not just any Help Center. Help!</p>

      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports error for `Help Center` and suggests `Lintercorp Help Center`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Help Center`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Help Center`'
      end
    end

    context 'when violation starts with uppercase and suggestion starts with lowercase' do
      violation_set_1 = 'Apps'
      suggestion_1 = 'apps'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>Apps, apps, and away. Big Apps and salutations. Did Britney sing apps, I did it again? Apps a daisy.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Apps` and suggests `apps`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Apps`'
        expect(linter_errors[0][:message]).to include 'Do use `apps`'
      end
    end

    context 'when violation is contained in another violation in rule list' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'
      violation_set_2 = 'Apps'
      suggestion_2 = 'apps'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>App Apply. Five hundred App. George, App king. George—App king. App now, time is running out.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `App` and suggests `app`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `App`'
        expect(linter_errors[0][:message]).to include 'Do use `app`'
      end
    end

    context 'when violation is compound word starting with uppercase and suggestion starts with lowercase' do
      violation_set_1 = 'Payment Gateways'
      suggestion_1 = 'payment gateways'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>Payment Gateways are a gateway drug.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Payment Gateways` and suggests `payment gateways`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Payment Gateways`'
        expect(linter_errors[0][:message]).to include 'Do use `payment gateways`'
      end
    end

    context 'when violation and suggestion are compound words starting with uppercase' do
      violation_set_1 = 'Lintercorp partner'
      suggestion_1 = 'Lintercorp Partner'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>Are you a Lintercorp partner, partner?</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Lintercorp partner` and suggests `Lintercorp Partner`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Lintercorp partner`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Partner`'
      end
    end

    context 'when violation contains single dumb quote' do
      violation_set_1 = 'store\'s dashboard'
      suggestion_1 = 'Lintercorp dashboard'
      case_insensitive_1 = true

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'case_insensitive' => case_insensitive_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>Welcome to the Store's dashboard.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `store\'s dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store\'s dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context 'when violation contains single smart quote' do
      violation_set_1 = 'store’s dashboard'
      suggestion_1 = 'Lintercorp dashboard'
      case_insensitive_1 = true

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'case_insensitive' => case_insensitive_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>Welcome to the Store’s dashboard.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `store’s dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `store’s dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context 'when file contains double dumb quote' do
      violation_set_1 = 'backend store dashboard'
      suggestion_1 = 'Lintercorp dashboard'
      case_insensitive_1 = true

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'case_insensitive' => case_insensitive_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>The "backend store dashboard is not what it seems.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `backend store dashboard` and suggests `Lintercorp dashboard`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `backend store dashboard`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp dashboard`'
      end
    end

    context 'when text node starts on line after parent' do
      violation_set_1 = 'Lintercorp Plus client'
      suggestion_1 = 'Lintercorp Plus merchant'
      case_insensitive_1 = true
      violation_set_2 = 'Lintercorp plus'
      suggestion_2 = 'Lintercorp Plus'
      case_insensitive_2 = false

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'case_insensitive' => case_insensitive_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2,
            'case_insensitive' => case_insensitive_2
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>
        The Lintercorp Plus client is upset.
        </p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `Lintercorp Plus client` and suggests `Lintercorp Plus merchant`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `Lintercorp Plus client`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp Plus merchant`'
      end
      it 'calculates correct line numbers' do
        expect(linter_errors[0][:line]).to eq(2)
      end
    end

    context 'when text node has multiple lines' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'
      violation_set_2 = 'Apps'
      suggestion_2 = 'apps'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>

        The App is not what it seems.
        The Apps are not what they seem.
        </p>
      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'calculates correct line numbers' do
        expect(linter_errors[0][:line]).to eq(3)
        expect(linter_errors[1][:line]).to eq(4)
      end
    end

    context 'when text node starts on same line as parent and has multiple lines' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'
      violation_set_2 = 'Apps'
      suggestion_2 = 'apps'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>The App is not what it seems.
        The Apps are not what they seem.
        </p>
      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'calculates correct line numbers' do
        expect(linter_errors[0][:line]).to eq(1)
        expect(linter_errors[1][:line]).to eq(2)
      end
    end

    context 'when an extra line is present above parent node' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end
      let(:file) { <<~FILE }
        <div></div>
        <div>
          The App
        </div>
      FILE

      it 'reports 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'calculates correct line numbers' do
        expect(linter_errors[0][:line]).to eq(3)
      end
    end

    context 'when violation is dumb single quote' do
      violation_set_1 = '\''
      suggestion_1 = '’'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          }
        ]
      end
      let(:file) { <<~FILE }
      The 'App' is not what it seems.
      FILE

      it 'reports 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports an error for `\'` and suggests `’`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `\'`'
        expect(linter_errors[0][:message]).to include 'Do use `’`'
      end
    end

    context 'when violation is regex' do
      violation_set_1 = '\D+(-|–|—)\$?\d+'
      suggestion_1 = '– (minus sign) to denote negative numbers'
      pattern_description_1 = '— (em dash), – (en dash), or - (hyphen) to denote negative numbers'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'pattern_description' => pattern_description_1
          }
        ]
      end
      let(:file) { <<~FILE }
      The -65 and the –$65
      FILE

      it 'reports 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports an error for `– (en dash) or - (hyphen)` and suggests `– (minus sign)`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `— (em dash), – (en dash), or - (hyphen)'
        expect(linter_errors[0][:message]).to include 'Do use `– (minus sign) to denote negative numbers`'
      end
    end

    context 'when addendum is present' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'
      violation_set_2 = 'Apps'
      suggestion_2 = 'apps'

      let(:linter_config) do
        {
          'rule_set' => rule_set,
          'addendum' => addendum
        }
      end

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          }
        ]
      end
      let(:addendum) { 'Addendum!' }

      context 'when file is empty' do
        let(:file) { '' }

        it 'does not report any errors' do
          expect(linter_errors).to eq []
        end
      end

      context 'when file contains violation' do
        let(:file) { <<~FILE }
          <p>All about that App</p>
        FILE

        it 'reports 1 error' do
          expect(linter_errors.size).to eq 1
        end

        it 'reports an error with its message ending with the addendum' do
          expect(linter_errors.first[:message]).to end_with addendum
        end
      end
    end

    context 'when addendum is absent' do
      violation_set_1 = 'App'
      suggestion_1 = 'app'
      violation_set_2 = 'Apps'
      suggestion_2 = 'apps'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          }
        ]
      end

      context 'when file is empty' do
        violation_set_1 = 'App'
        suggestion_1 = 'app'
        violation_set_2 = 'Apps'
        suggestion_2 = 'apps'
        let(:linter_config) do
          {
            'rule_set' => rule_set
          }
        end
        let(:rule_set) do
          [
            {
              'violation' => violation_set_1,
              'suggestion' => suggestion_1
            },
            {
              'violation' => violation_set_2,
              'suggestion' => suggestion_2
            }
          ]
        end
        let(:file) { '' }
        it 'does not report any errors' do
          expect(linter_errors).to eq []
        end
      end
    end
  end
end
