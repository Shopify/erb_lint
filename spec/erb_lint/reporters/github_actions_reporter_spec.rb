# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Reporters::GithubActionsReporter do
  describe ".show" do
    subject { described_class.new(stats, false).show }

    let(:stats) do
      ERBLint::Stats.new(
        found: 2,
        processed_files: {
          "app/views/subscriptions/_loader.html.erb" => offenses,
        },
        corrected: 1,
      )
    end

    let(:offenses) do
      [
        instance_double(
          ERBLint::Offense,
          message: "Extra space detected where there should be no space.",
          line_number: 1,
          column: 7,
          simple_name: "SpaceInHtmlTag",
          severity: :warning,
          last_line: 1,
          last_column: 9,
          length: 2,
        ),
        instance_double(
          ERBLint::Offense,
          message: "Remove newline before `%>` to match start of tag.",
          line_number: 52,
          column: 10,
          simple_name: "ClosingErbTagIndent",
          severity: :error,
          last_line: 54,
          last_column: 10,
          length: 10,
        ),
      ]
    end

    let(:expected_lines) do
      [
        "::error file=app/views/subscriptions/_loader.html.erb,line=1,col=7" \
          "::SpaceInHtmlTag: Extra space detected where there should be no space.",
        "::warning file=app/views/subscriptions/_loader.html.erb,line=52,col=10" \
          "::ClosingErbTagIndent: Remove newline before `%25>` to match start of tag.",
      ].join("\n")
    end

    it "displays formatted offenses output" do
      expect { subject }.to(output(expected_lines + "\n").to_stdout)
    end
  end
end
