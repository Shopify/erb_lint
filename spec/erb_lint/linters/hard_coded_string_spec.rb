# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::HardCodedString do
  let(:linter_config) do
    described_class.config_schema.new
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject(:offenses) { linter.offenses(processed_source) }

  context 'when file contains hard coded string' do
    let(:file) { <<~FILE }
      <span> Hello </span>
    FILE

    it { expect(subject).to eq [untranslated_string_error(7..11, 'String not translated: Hello')] }
  end

  context 'when file contains nested hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <div id="hero">
          <span id="cat"> Example </span>
        </div>
      </span>
    FILE

    it { expect(subject).to eq [untranslated_string_error(61..67, 'String not translated: Example')] }
  end

  context 'when file contains a mix of hard coded string and erb' do
    let(:file) { <<~FILE }
      <span><%= foo %> Example </span>
    FILE

    it { expect(subject).to eq [untranslated_string_error(17..23, 'String not translated: Example')] }
  end

  context 'when file contains hard coded string nested inside erb' do
    let(:file) { <<~FILE }
      <span>
        <% foo do %>
          <span> Example </span>
        <% end %>
      </span>
    FILE

    it { expect(subject).to eq [untranslated_string_error(33..39, 'String not translated: Example')] }
  end

  context 'when file contains multiple hard coded string' do
    let(:file) { <<~FILE }
      <span> Example </span>
      <span> Foo </span>
      <span> Test </span>
    FILE

    it 'find all offenses' do
      expect(subject).to eq [
        untranslated_string_error(7..13, 'String not translated: Example'),
        untranslated_string_error(30..32, 'String not translated: Foo'),
        untranslated_string_error(49..52, 'String not translated: Test')
      ]
    end
  end

  context 'when file does not contain any hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <div id="hero">
          <span id="cat"> <%= t(:hello) %> </span>
        </div>
      </span>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'when file contains irrelevant hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <% discounted_by %>%


      </span>
    FILE

    it 'add offense' do
      expected = untranslated_string_error(
        26..26,
        "Consider using Rails helpers to move out the single character \`%\` from the html."
      )
      expect(subject).to eq [expected]
    end
  end

  context 'when file contains hard coded string inside javascript' do
    let(:file) { <<~FILE }
      <script type="text/template">
        const TEMPLATE = `
          <div class="example" data-modal-backdrop>
            <span> Hardcoded String </span>
          </div>`;
      </script>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'when file contains hard coded string following a javascript block' do
    let(:file) { <<~FILE }
      <script type="text/template">
        const TEMPLATE = `
          <div class="example" data-modal-backdrop>
            <span> Hardcoded String </span>
          </div>`;
      </script>
      Example
    FILE

    it { expect(subject).to eq [untranslated_string_error(158..164, "String not translated: Example")] }
  end

  context 'when file contains multiple chunks of hardcoded strings' do
    let(:file) { <<~FILE }
      <div>
        Foo <%= bar %> Foo2 <% bar %> Foo3
      </div>
    FILE

    it do
      expected = [
        untranslated_string_error(8..10, "String not translated: Foo"),
        untranslated_string_error(23..26, "String not translated: Foo2"),
        untranslated_string_error(38..41, "String not translated: Foo3")
      ]

      expect(subject).to eq expected
    end
  end

  context 'when file contains multiple hardcoded strings that spans on multiple lines' do
    let(:file) { <<~FILE }
      <div>
        Foo
        John
        Albert
        Smith
      </div>
    FILE

    it 'creates a new offense for each' do
      expected = [
        untranslated_string_error(8..10, "String not translated: Foo"),
        untranslated_string_error(14..17, "String not translated: John"),
        untranslated_string_error(21..26, "String not translated: Albert"),
        untranslated_string_error(30..34, "String not translated: Smith")
      ]

      expect(subject).to eq expected
    end
  end

  private

  def untranslated_string_error(range, string)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range.min, range.max),
      string
    )
  end
end
