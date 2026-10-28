# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::ParserErrors do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  before { linter.run(processed_source) }

  describe "offenses" do
    subject { offenses }

    context "when file is valid" do
      let(:file) { "<a>" }
      it { expect(subject).to(eq([])) }
    end

    context "when file is invalid" do
      let(:file) { "<>" }
      it do
        expect(subject).to(eq([
          build_offense(1..1, "expected '/' or tag name (at >)"),
        ]))
      end
    end

    context "when a less-than symbol is followed by whitespace in HTML text" do
      let(:file) do
        <<~HTML
          <tr>
            <td>< 2 times per year</td>
          </tr>
        HTML
      end
      let(:processed_source) { ERBLint::ProcessedSource.new("file.html.erb", file) }

      it "does not report a parser error or consume the following closing tag" do
        expect(subject).to(eq([]))
        expect(processed_source.parser.nodes_with_type(:tag).map { |node| BetterHtml::Tree::Tag.from_node(node).name })
          .to(eq(["tr", "td", "td", "tr"]))
        expect(processed_source.parser.nodes_with_type(:text).map(&:loc).map(&:source))
          .to(include("< 2 times per year"))
      end
    end

    context "when a less-than symbol is used for shell input redirection" do
      let(:file) do
        <<~SHELL
          file=/etc/passwd

          while IFS= read -r line
          do
            echo "$line"
          done < "$file"
        SHELL
      end
      let(:processed_source) { ERBLint::ProcessedSource.new("test.sh.erb", file) }

      it { expect(subject).to(eq([])) }
    end

    context "when multiple less-than symbols are followed by whitespace in HTML text" do
      let(:file) { "<p>1 < 2 and 3 < 4</p>" }
      let(:processed_source) { ERBLint::ProcessedSource.new("file.html.erb", file) }

      it "retries each literal symbol without losing the original text or closing tag" do
        expect(subject).to(eq([]))
        expect(processed_source.parser.nodes_with_type(:tag).map { |node| BetterHtml::Tree::Tag.from_node(node).name })
          .to(eq(["p", "p"]))
        expect(processed_source.parser.nodes_with_type(:text).map(&:loc).map(&:source))
          .to(include("1 < 2 and 3 < 4"))
      end
    end

    context "when a text less-than symbol and invalid markup coexist" do
      let(:file) { "<p>< 2 items</p><>" }
      let(:processed_source) { ERBLint::ProcessedSource.new("file.html.erb", file) }

      it "still reports the invalid markup" do
        expect(subject.map(&:message)).to(eq(["expected '/' or tag name (at >)"]))
      end
    end

    context "escaped erb is ignored" do
      let(:file) { "<%%= erb %>" }
      it do
        expect(subject).to(eq([]))
      end
    end
  end

  private

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message,
    )
  end
end
