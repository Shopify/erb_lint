# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::StrictLocals do
  let(:linter_config) { described_class.config_schema.new }
  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }

  subject { linter.offenses }
  before { linter.run(processed_source) }

  context "when the ERB is not a view partial" do
    let(:file) { <<~FILE }
      <div>
        <%= foo %>
      </div>
    FILE

    context "when the ERB is a simple file" do
      let(:processed_source) { ERBLint::ProcessedSource.new("file.html.erb", file) }

      it "does not report any offenses" do
        expect(subject).to(be_empty)
      end
    end

    context "when the ERB is a nested file" do
      let(:processed_source) { ERBLint::ProcessedSource.new("foo/bar/baz/my_file.html.erb", file) }

      it "does not report any offenses" do
        expect(subject).to(be_empty)
      end
    end
  end

  context "when the ERB is empty" do
    let(:file) { "" }
    let(:processed_source) { ERBLint::ProcessedSource.new("_file.html.erb", file) }

    it "does not report any offenses" do
      expect(subject).to(be_empty)
    end
  end

  context "when the ERB is a view partial" do
    let(:processed_source) { ERBLint::ProcessedSource.new("_file.html.erb", file) }

    context "when the ERB contains a strict locals declaration at the top of the file" do
      let(:file) { <<~FILE }
        <%# locals: (foo: "bar") %>
        <div>
          <%= foo %>
        </div>
      FILE

      it "does not report any offenses" do
        expect(subject).to(be_empty)
      end
    end

    context "when the ERB contains a strict locals declaration anywhere else in the file" do
      let(:file) { <<~FILE }
        <div>
          <%= foo %>
        </div>
        <%# locals: (foo: "bar") %>
      FILE

      it "does not report any offenses" do
        expect(subject).to(be_empty)
      end
    end

    context "when the ERB contains an empty strict locals declaration" do
      let(:file) { <<~FILE }
        <%# locals: () %>
        <div>
          <%= foo %>
        </div>
      FILE

      it "does not report any offenses" do
        expect(subject).to(be_empty)
      end
    end

    context "when the ERB does not contain a strict locals declaration" do
      let(:file) { <<~FILE }
        <div>
          <%= foo %>
        </div>
      FILE
      let(:corrector) { ERBLint::Corrector.new(processed_source, subject) }
      let(:corrected_content) { corrector.corrected_content }

      it "reports an offense" do
        expect(subject.size).to(eq(1))
      end

      it "reports the suggested fix" do
        expect(subject.first.message).to(include(
          "Missing strict locals declaration.\n",
          "Add <%# locals: () %> at the top of the file to enforce strict locals.",
        ))
      end

      it "corrects the file" do
        expect(corrected_content).to(eq("<%# locals: () %>\n<div>\n  <%= foo %>\n</div>\n"))
      end
    end
  end
end
