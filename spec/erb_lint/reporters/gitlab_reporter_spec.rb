# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Reporters::GitlabReporter do
  describe ".show" do
    subject { described_class.new(stats, false).show }

    let(:stats) do
      ERBLint::Stats.new(
        found: 2,
        processed_files: {
          "app/views/subscriptions/_loader.html.erb" => offenses,
        },
        corrected: 1
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
          severity: "info",
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
          severity: "warning",
          last_line: 54,
          last_column: 10,
          length: 10,
        ),
      ]
    end

    let(:expected_hash) do
      [
        {
          description: "Extra space detected where there should be no space.",
          check_name: "SpaceInHtmlTag",
          fingerprint: "5a259c7cafa2c9ca229dfd7d21536698",
          severity: "info",
          location: {
            path: "app/views/subscriptions/_loader.html.erb",
            lines: {
              begin: 1,
              end: 1,
            },
          },
        },
        {
          description: "Remove newline before `%>` to match start of tag.",
          check_name: "ClosingErbTagIndent",
          fingerprint: "60b4ed2120c7abeebebb43fba4a19559",
          severity: "warning",
          location: {
            path: "app/views/subscriptions/_loader.html.erb",
            lines: {
              begin: 52,
              end: 54,
            },
          },
        },
      ]
    end

    it "displays formatted offenses output" do
      expect { subject }.to(output(expected_hash.to_json + "\n").to_stdout)
    end
  end
end
