# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Reporters::CompactReporter do
  describe ".show" do
    let(:autocorrect) { false }
    let(:show_linter_names) { false }
    subject { described_class.new(stats, autocorrect, show_linter_names).show }

    let(:stats) do
      ERBLint::Stats.new(
        ignored: 2,
        found: 4,
        processed_files: {
          "app/views/users/show.html.erb" => show_file_offenses,
          "app/views/shared/_notifications.html.erb" => notification_file_offenses,
        },
      )
    end

    let(:show_file_offenses) do
      [
        instance_double(
          ERBLint::Offense,
          simple_name: "SpaceInHtmlTag",
          message: "Extra space detected where there should be no space.",
          line_number: 61,
          column: 10,
        ),
        instance_double(
          ERBLint::Offense,
          simple_name: "FinalNewline",
          message: "Remove multiple trailing newline at the end of the file.",
          line_number: 125,
          column: 1,
        ),
        instance_double(
          ERBLint::Offense,
          simple_name: "TrailingComma",
          message: "Trailing comma expected.",
          line_number: 145,
          column: 4,
          severity: :info,
        ),
      ]
    end

    let(:notification_file_offenses) do
      [
        instance_double(
          ERBLint::Offense,
          simple_name: "SpaceIndentation",
          message: "Indent with spaces instead of tabs.",
          line_number: 3,
          column: 1,
        ),
        instance_double(
          ERBLint::Offense,
          simple_name: "SpaceInHtmlTag",
          message: "Extra space detected where there should be no space.",
          line_number: 7,
          column: 1,
        ),
        instance_double(
          ERBLint::Offense,
          simple_name: "TrailingComma",
          message: "Trailing comma expected.",
          line_number: 8,
          column: 4,
          severity: :info,
        ),
      ]
    end

    it "displays formatted offenses output" do
      expect { subject }.to(output(<<~MESSAGE).to_stdout)
        app/views/users/show.html.erb:61:10: Extra space detected where there should be no space.
        app/views/users/show.html.erb:125:1: Remove multiple trailing newline at the end of the file.
        app/views/users/show.html.erb:145:4: Trailing comma expected.
        app/views/shared/_notifications.html.erb:3:1: Indent with spaces instead of tabs.
        app/views/shared/_notifications.html.erb:7:1: Extra space detected where there should be no space.
        app/views/shared/_notifications.html.erb:8:4: Trailing comma expected.
      MESSAGE
    end

    context "with show linter names enabled" do
      let(:show_linter_names) { true }

      it "displays formatted offenses output with linter names" do
        expect { subject }.to(output(<<~MESSAGE).to_stdout)
          app/views/users/show.html.erb:61:10: [SpaceInHtmlTag] Extra space detected where there should be no space.
          app/views/users/show.html.erb:125:1: [FinalNewline] Remove multiple trailing newline at the end of the file.
          app/views/users/show.html.erb:145:4: [TrailingComma] Trailing comma expected.
          app/views/shared/_notifications.html.erb:3:1: [SpaceIndentation] Indent with spaces instead of tabs.
          app/views/shared/_notifications.html.erb:7:1: [SpaceInHtmlTag] Extra space detected where there should be no space.
          app/views/shared/_notifications.html.erb:8:4: [TrailingComma] Trailing comma expected.
        MESSAGE
      end
    end

    it "outputs offenses summary to stderr" do
      expect { subject }.to(output(<<~MESSAGE).to_stderr)
        #{Rainbow("2 error(s) were ignored in ERB files").yellow}
        #{Rainbow("4 error(s) were found in ERB files").red}
      MESSAGE
    end
  end
end
