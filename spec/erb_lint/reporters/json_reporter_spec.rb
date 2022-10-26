# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Reporters::JsonReporter do
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
          last_line: 54,
          last_column: 10,
          length: 10,
        ),
      ]
    end

    let(:expected_hash) do
      {
        metadata: {
          erb_lint_version: ERBLint::VERSION,
          ruby_engine: RUBY_ENGINE,
          ruby_version: RUBY_VERSION,
          ruby_patchlevel: RUBY_PATCHLEVEL.to_s,
          ruby_platform: RUBY_PLATFORM,
        },
        files: [{
          path: "app/views/subscriptions/_loader.html.erb",
          offenses: [
            {
              linter: "SpaceInHtmlTag",
              message: "Extra space detected where there should be no space.",
              location: {
                start_line: 1,
                start_column: 7,
                last_line: 1,
                last_column: 9,
                length: 2,
              },
            },
            {
              linter: "ClosingErbTagIndent",
              message: "Remove newline before `%>` to match start of tag.",
              location: {
                start_line: 52,
                start_column: 10,
                last_line: 54,
                last_column: 10,
                length: 10,
              },
            },
          ],
        }],
        summary: {
          offenses: 2,
          inspected_files: 1,
          corrected: 1,
        },
      }
    end

    it "displays formatted offenses output" do
      expect { subject }.to(output(expected_hash.to_json + "\n").to_stdout)
    end
  end
end
