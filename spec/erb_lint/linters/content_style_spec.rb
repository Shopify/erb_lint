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

  context 'when the rule set is empty' do
    let(:rule_set) { [] }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any errors' do
        expect(linter_errors).to eq []
      end
    end
  end

  context 'when the rule set contains violations' do
    context '- rule is case-insensitive
    - file contains violation with different case from suggestion (`Drop down`)
    - file contains violation with same case as suggestion (`dropdown`)
    - file contains suggestion (`drop-down`)' do
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

    context '- suggestion is prefix + violation (`Lintercorp Help Center`)
    - file contains suggestion (`Lintercorp Help Center`)
    - file contains violation (`Help Center`)' do
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

    context '- suggestion is prefix + violation (`Lintercorp theme store`)
    - file contains violation (`theme store`)
    - file contains violation (`Theme Store`)
    - violation contains other violations (`Theme Store` contains `Theme` and `Store`)' do
      # Note that this test will fail if the violations contained within another
      # violation appear earlier in the rule list than the containing violation.
      violation_set_1 = ['theme store', 'Theme Store']
      suggestion_1 = 'Lintercorp theme store'
      violation_set_2 = 'Theme'
      suggestion_2 = 'theme'
      violation_set_3 = 'Themes'
      suggestion_3 = 'themes'
      violation_set_4 = 'Store'
      suggestion_4 = 'store'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1
          },
          {
            'violation' => violation_set_2,
            'suggestion' => suggestion_2
          },
          {
            'violation' => violation_set_3,
            'suggestion' => suggestion_3
          },
          {
            'violation' => violation_set_4,
            'suggestion' => suggestion_4
          }
        ]
      end
      let(:file) { <<~FILE }
        <p>The theme store called. They are out of themes at the Theme Store.</p>

      FILE

      it 'reports 2 errors' do
        expect(linter_errors.size).to eq 2
      end

      it 'reports errors for `theme store` and `Theme Store` and suggests `Lintercorp theme store`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `theme store`'
        expect(linter_errors[0][:message]).to include 'Do use `Lintercorp theme store`'
        expect(linter_errors[1][:message]).to include 'Don\'t use `Theme Store`'
        expect(linter_errors[1][:message]).to include 'Do use `Lintercorp theme store`'
      end
    end

    context '- violation starts with uppercase character (`Apps`)
    - suggestion starts with lowercase character (`apps`)
    - file contains violation (`Big Apps`)
    - file contains two potential false positives (the string and a sentence within the string both start
      with `Apps`)' do
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

    context '- violation starts with uppercase character (`App`)
    - suggestion starts with lowercase character (`app`)
    - violation (`App`) contained in another violation (`Apps`)
    - file contains a violation (`Five hundred App`)
    - file contains two potential false positives
      (the string and a sentence within the string both start with `App`)' do
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
        <p>App Apply. Five hundred App. App now, time is running out.</p>
      FILE

      it 'reports 1 errors' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports errors for `App` and suggests `app`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `App`'
        expect(linter_errors[0][:message]).to include 'Do use `app`'
      end
    end

    context '- violation has multiple words starting with uppercase characters (`Payment Gateways`)
    - suggestion contains only lowercase characters (`payment gateways`)' do
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

    context '- violation has multiple words and first word of violation starts with uppercase character (`Lintercorp
      partner`)
    - suggestion has multiple words, both starting with uppercase characters (`Lintercorp Partner`)' do
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

    context '- file contains violation with a dumb single quote (`Store\'s dashboard`)' do
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

    context '- violation has a smart single quote (`Store’s dashboard`)
    - violation contained in prior violation' do
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

    context '- file has a dumb double quote (`"backend store dashboard`)' do
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

    context '- text node starts on line after parent' do
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
      it 'calculates the correct line number' do
        expect(linter_errors[0][:line]).to eq(2)
      end
    end

    context '- text node has multiple lines' do
      # This test will only handle following lines once we build in multiline functionality
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

      it 'strips the content after the first line and reports only 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports an error for `App` and suggests `app`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `App`'
        expect(linter_errors[0][:message]).to include 'Do use `app`'
      end
      it 'calculates a correct first line number' do
        expect(linter_errors[0][:line]).to eq(3)
      end
    end

    context '- text node starts on same line as parent but has multiple lines' do
      # This test will only handle following lines once we build in multiline functionality
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

      it 'strips the content after the first line and reports only 1 error' do
        expect(linter_errors.size).to eq 1
      end

      it 'reports an error for `App` and suggests `app`' do
        expect(linter_errors[0][:message]).to include 'Don\'t use `App`'
        expect(linter_errors[0][:message]).to include 'Do use `app`'
      end
      it 'calculates a correct first line number' do
        expect(linter_errors[0][:line]).to eq(1)
      end
    end

    context '- dumb single quote is violation and file has dumb single quote' do
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

    context '- violation is regex' do
      violation_set_1 = '\D+(-|–|—)\$?\d+'
      suggestion_1 = '– (minus sign) to denote negative numbers'
      regex_description_1 = '— (em dash), – (en dash), or - (hyphen) to denote negative numbers'

      let(:rule_set) do
        [
          {
            'violation' => violation_set_1,
            'suggestion' => suggestion_1,
            'regex_description' => regex_description_1
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

    context 'when an addendum is present' do
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

      context 'when the file is empty' do
        let(:file) { '' }

        it 'does not report any errors' do
          expect(linter_errors).to eq []
        end
      end

      context 'when the file contains a violation' do
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

    context 'when an addendum is absent' do
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

      context 'when the file is empty' do
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
