# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::HardCodedString do
  let(:linter_options) { {} }
  let(:linter_config) do
    described_class.config_schema.new(linter_options)
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject { linter.offenses }
  before { linter.run(processed_source) }

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
      <span>Example </span>
      <%= foo %>
    FILE

    it { expect(subject).to eq [untranslated_string_error(6..12, 'String not translated: Example')] }
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

  context 'when file contains blacklisted extraction' do
    let(:file) { <<~FILE }
      &nbsp;
    FILE

    it { expect(subject).to eq [] }
  end

  context 'when file does not contain any hard coded string and only has erb code' do
    let(:file) { <<~FILE }
      <% one %>
      <% two %>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'when file contains irrelevant hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <% discounted_by %>%


      </span>
    FILE

    it 'does not add offense' do
      expect(subject).to eq []
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
        <%= bar %> Foo Foo2 <% bar %> Foo3
        Test
      </div>
    FILE

    it do
      expected = [
        untranslated_string_error(8..41, "String not translated: <%= bar %> Foo Foo2 <% bar %> Foo3"),
        untranslated_string_error(45..48, "String not translated: Test")
      ]

      expect(subject).to eq expected
    end
  end

  context 'when file contains multiple chunks of hardcoded strings seperated by a period' do
    let(:file) { <<~FILE }
      <div>
        <%= bar %>. Foo Foo2 <% bar %>. Foo3
        Test
      </div>
    FILE

    it do
      expected = [
        untranslated_string_error(8..43, "String not translated: <%= bar %>. Foo Foo2 <% bar %>. Foo3"),
        untranslated_string_error(47..50, "String not translated: Test")
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
        <%= test %>
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

  context 'when file contains multiple hardcoded with a string having an interpolation' do
    let(:file) { <<~FILE }
      <div>
        Foo
        John
        Albert
        Smith <%= test %>
      </div>
    FILE

    it 'creates a new offense for each' do
      expected = [
        untranslated_string_error(8..10, "String not translated: Foo"),
        untranslated_string_error(14..17, "String not translated: John"),
        untranslated_string_error(21..26, "String not translated: Albert"),
        untranslated_string_error(30..46, "String not translated: Smith <%= test %>")
      ]

      expect(subject).to eq expected
    end
  end

  context 'when file contains a string with an interpolation spanning on multiple lines' do
    let(:file) { <<~FILE }
      <div>
        Smith <%= test
          something: "foo",
          something2: "bar" %>
      </div>
    FILE

    it 'creates a single offense' do
      expected = [
        untranslated_string_error(
          8..68,
          "String not translated: Smith <%= test\n    something: \"foo\",\n    something2: \"bar\" %>"
        )
      ]

      expect(subject).to eq expected
    end
  end

  context 'with corrector' do
    let(:tempfile) do
      @tempfile = Tempfile.new(['my_class', '.rb']).tap do |f|
        f.write(<<~EOM)
          class I18nCorrector
            attr_reader :node

            def initialize(filename, range)
            end

            def autocorrect(node, tag_start:, tag_end:)
              ->(corrector) do
                node
              end
            end
          end
        EOM
        f.rewind
      end
    end

    after(:each) do
      tempfile.unlink
      tempfile.close
    end

    let(:linter_options) do
      { corrector: { path: tempfile.path, name: 'I18nCorrector' } }
    end

    let(:file) { <<~FILE }
      <span> Hello </span>
    FILE

    it 'require the corrector' do
      offense = untranslated_string_error(7..11, 'String not translated: Hello')
      linter.autocorrect(processed_source, offense)

      expect(defined?(I18nCorrector)).to eq('constant')
    end

    it 'calls the autocorrect method and pass a rubocop node' do
      offense = untranslated_string_error(7..11, 'String not translated: Hello')
      node = linter.autocorrect(processed_source, offense).call('')

      expect(node.str_content).to eq('Hello')
    end

    context 'with interpolations' do
      let(:file) { <<~FILE }
        Foo <%= bar %> Foo2 <% bar %> Foo3
      FILE

      it 'calls autocorrect method and pass a rubocop node with method interpolation' do
        offense = untranslated_string_error(0..33, 'String not translated: Foo <%= bar %> Foo2 <% bar %> Foo3')
        node = linter.autocorrect(processed_source, offense).call('')

        expect(node.parent.source).to eq("\"Foo \#{bar} Foo2 \#{bar} Foo3\"")
      end
    end

    context 'without corrector' do
      let(:linter_options) { {} }

      it 'rescue the MissingCorrector error when no corrector option is passed' do
        offense = untranslated_string_error(7..11, 'String not translated: Hello')

        expect(linter.autocorrect(processed_source, offense)).to eq(nil)
      end
    end

    context 'can not constanize the class' do
      let(:linter_options) do
        { corrector: { path: tempfile.path, name: 'UnknownClass' } }
      end

      it 'does not continue the auto correction when the class passed is not whitelisted' do
        offense = untranslated_string_error(7..11, 'String not translated: Hello')

        error = ERBLint::Linters::HardCodedString::ForbiddenCorrector
        expect { linter.autocorrect(processed_source, offense) }.to raise_error(error)
      end
    end
  end

  private

  def untranslated_string_error(range, string)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      string
    )
  end
end
