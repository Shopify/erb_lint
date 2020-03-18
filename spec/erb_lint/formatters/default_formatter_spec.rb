# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Formatters::DefaultFormatter do
  describe '.format' do
    subject { described_class.new(offenses, filename, autocorrect).format }

    let(:filename) { 'app/views/subscriptions/_loader.html.erb' }
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
        result = subject

        expect(result.size).to(eq(2))

        expect(result[0]).to(eq(<<~OUT))
          Extra space detected where there should be no space.
          In file: app/views/subscriptions/_loader.html.erb:1

        OUT

        expect(result[1]).to(eq(<<~OUT))
          Remove newline before `%>` to match start of tag.
          In file: app/views/subscriptions/_loader.html.erb:52

        OUT
      end
    end

    context 'when autocorrect is true' do
      let(:autocorrect) { true }

      it 'generates formatted offenses with no corrected warning' do
        result = subject

        expect(result.size).to(eq(2))

        expect(result[0]).to(eq(<<~OUT))
          Extra space detected where there should be no space.\e[31m (not autocorrected)\e[0m
          In file: app/views/subscriptions/_loader.html.erb:1

        OUT

        expect(result[1]).to(eq(<<~OUT))
          Remove newline before `%>` to match start of tag.\e[31m (not autocorrected)\e[0m
          In file: app/views/subscriptions/_loader.html.erb:52

        OUT
      end
    end
  end
end
