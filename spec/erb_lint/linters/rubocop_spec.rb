# frozen_string_literal: true

require 'spec_helper'
require 'better_html'

describe ERBLint::Linters::Rubocop do
  let(:linter_config) do
    described_class.config_schema.new(
      only: ['ErbLint/ArbitraryRule'],
      rubocop_config: {
        require: [File.expand_path('../../fixtures/cops/example_cop', __FILE__)],
        AllCops: {
          TargetRubyVersion: '2.4',
        },
      },
    )
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject(:offenses) { linter.offenses(processed_source) }

  context 'when rubocop finds no offenses' do
    let(:file) { <<~FILE }
      <% not_banned_method %>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'when rubocop finds offenses in ruby statements' do
    let(:file) { <<~FILE }
      <% banned_method %>
    FILE

    it { expect(subject).to eq [arbitrary_error_message(3..15)] }
    it { expect(subject.first.source_range.source).to eq "banned_method" }
  end

  context 'when rubocop finds offenses in ruby expressions' do
    let(:file) { <<~FILE }
      <%= banned_method %>
    FILE

    it { expect(subject).to eq [arbitrary_error_message(4..16)] }
  end

  context 'partial ruby statements are ignored' do
    let(:file) { <<~FILE }
      <% if banned_method %>
        foo
      <% end %>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'statements with partial block expression is processed' do
    let(:file) { <<~FILE }
      <% banned_method.each do %>
        foo
      <% end %>
    FILE

    it { expect(subject).to eq [arbitrary_error_message(3..15)] }
  end

  context 'line numbers take into account both html and erb newlines' do
    let(:file) { <<~FILE }
      <div>
        <%
          if foo?
            banned_method
          end
        %>
      </div>
    FILE

    it { expect(subject).to eq [arbitrary_error_message(29..41)] }
  end

  context 'supports loading nested config' do
    let(:linter_config) do
      described_class.config_schema.new(
        only: ['ErbLint/ArbitraryRule'],
        rubocop_config: {
          inherit_from: 'custom_rubocop.yml',
          AllCops: {
            TargetRubyVersion: '2.3',
          },
        },
      )
    end

    let(:nested_config) do
      {
        'ErbLint/ArbitraryRule': {
          'Enabled': false
        }
      }.deep_stringify_keys
    end

    before do
      expect(file_loader).to receive(:yaml).with('custom_rubocop.yml').and_return(nested_config)
    end

    context 'rules from nested config are merged' do
      let(:file) { <<~FILE }
        <% banned_method %>
      FILE

      it { expect(subject).to eq [] }
    end
  end

  context 'code is aligned to the column matching start of erb tag' do
    let(:linter_config) do
      described_class.config_schema.new(
        only: ['Layout/AlignParameters'],
        rubocop_config: {
          AllCops: {
            TargetRubyVersion: '2.4',
          },
          'Layout/AlignParameters': {
            Enabled: true,
            EnforcedStyle: 'with_fixed_indentation',
            SupportedStyles: %w(with_first_parameter with_fixed_indentation),
            IndentationWidth: nil,
          }
        },
      )
    end

    context 'when alignment is correct' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
          checked: true %>
      FILE

      it { expect(subject).to eq [] }
    end

    context 'when alignment is incorrect' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
              checked: true %>
      FILE

      it do
        expect(subject.size).to eq(1)
        expect(subject[0].source_range.begin_pos).to eq 25
        expect(subject[0].source_range.end_pos).to eq 38
        expect(subject[0].source_range.source).to eq "checked: true"
        expect(subject[0].line_range).to eq 2..2
        expect(subject[0].message).to \
          eq "Layout/AlignParameters: Use one level of indentation for "\
             "parameters following the first line of a multi-line method call."
      end
    end

    context 'correct alignment with html preceeding erb' do
      let(:file) { <<~FILE }
        <div><a><br><% ui_helper :foo,
                      checked: true %>
      FILE

      it { expect(subject).to eq [] }
    end
  end

  private

  def arbitrary_error_message(range)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range.min, range.max),
      "ErbLint/ArbitraryRule: An arbitrary rule has been violated."
    )
  end
end
