# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Reporters::MultilineReporter do
  describe ".show" do
    subject { described_class.new(stats, autocorrect, show_linter_names).show }

    let(:stats) do
      ERBLint::Stats.new(
        found: 2,
        processed_files: {
          "app/views/subscriptions/_loader.html.erb" => offenses,
        },
      )
    end

    let(:offenses) do
      [
        instance_double(
          ERBLint::Offense,
          simple_name: "SpaceInHtmlTag",
          message: "Extra space detected where there should be no space.",
          line_number: 1,
          column: 7,
        ),
        instance_double(
          ERBLint::Offense,
          simple_name: "ClosingErbTagIndent",
          message: "Remove newline before `%>` to match start of tag.",
          line_number: 52,
          column: 10,
        ),
      ]
    end

    context "when autocorrect is false" do
      let(:autocorrect) { false }
      let(:show_linter_names) { false }

      it "displays formatted offenses output" do
        expect { subject }.to(output(a_string_starting_with(<<~MESSAGE)).to_stderr)

          Extra space detected where there should be no space.
          In file: app/views/subscriptions/_loader.html.erb:1

          Remove newline before `%>` to match start of tag.
          In file: app/views/subscriptions/_loader.html.erb:52

        MESSAGE
      end
    end

    context "when show_linter_names is true" do
      let(:autocorrect) { false }
      let(:show_linter_names) { true }

      it "displays formatted offenses output" do
        expect { subject }.to(output(a_string_starting_with(<<~MESSAGE)).to_stderr)

          [SpaceInHtmlTag] Extra space detected where there should be no space.
          In file: app/views/subscriptions/_loader.html.erb:1

          [ClosingErbTagIndent] Remove newline before `%>` to match start of tag.
          In file: app/views/subscriptions/_loader.html.erb:52

        MESSAGE
      end
    end

    context "when autocorrect is true" do
      let(:autocorrect) { true }
      let(:show_linter_names) { false }

      it "displays not autocorrected warning" do
        expect { subject }.to(output(/(not autocorrected)/).to_stderr)
      end
    end
  end
end
