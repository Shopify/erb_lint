# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Formatters::MultilineFormatter do
  describe '.format' do
    subject { described_class.new(stats, autocorrect).format }

    let(:stats) do
      ERBLint::Stats.new(
        found: 2,
        files: {
          'app/views/subscriptions/_loader.html.erb' => offenses,
        }
      )
    end

    let(:offenses) do
      [
        instance_double(ERBLint::Offense,
                        message: 'Extra space detected where there should be no space.',
                        line_number: 1,
                        column: 7),
        instance_double(ERBLint::Offense,
                        message: 'Remove newline before `%>` to match start of tag.',
                        line_number: 52,
                        column: 10),
      ]
    end

    context 'when autocorrect is false' do
      let(:autocorrect) { false }

      it "generates formatted offenses without no corrected warning" do
        expect { subject }.to(output(<<~MESSAGE).to_stdout)
          Extra space detected where there should be no space.
          In file: app/views/subscriptions/_loader.html.erb:1

          Remove newline before `%>` to match start of tag.
          In file: app/views/subscriptions/_loader.html.erb:52

        MESSAGE
      end
    end

    context 'when autocorrect is true' do
      let(:autocorrect) { true }

      it 'generates formatted offenses with no corrected warning' do
        expect { subject }.to(output(<<~MESSAGE).to_stdout)
          Extra space detected where there should be no space.\e[31m (not autocorrected)\e[0m
          In file: app/views/subscriptions/_loader.html.erb:1

          Remove newline before `%>` to match start of tag.\e[31m (not autocorrected)\e[0m
          In file: app/views/subscriptions/_loader.html.erb:52
  
        MESSAGE
      end
    end
  end
end
