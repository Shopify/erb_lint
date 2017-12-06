# frozen_string_literal: true

require 'spec_helper'
require 'better_html'

describe ERBLint::Linters::Rubocop do
  let(:linter_config) do
    {
      only: ['ErbLint/ArbitraryRule'],
      require: [File.expand_path('../../fixtures/cops/example_cop', __FILE__)],
      AllCops: {
        TargetRubyVersion: '2.3',
      },
    }.deep_stringify_keys
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  subject(:linter_errors) { linter.lint_file(file) }

  context 'when rubocop finds no offenses' do
    let(:file) { <<~FILE }
      <% not_banned_method %>
    FILE

    it { expect(linter_errors).to eq [] }
  end

  context 'when rubocop finds offenses in ruby statements' do
    let(:file) { <<~FILE }
      <% banned_method %>
    FILE

    it { expect(linter_errors).to eq [arbitrary_error_message] }
  end

  context 'when rubocop finds offenses in ruby expressions' do
    let(:file) { <<~FILE }
      <%= banned_method %>
    FILE

    it { expect(linter_errors).to eq [arbitrary_error_message] }
  end

  context 'partial ruby statements are ignored' do
    let(:file) { <<~FILE }
      <% if banned_method %>
        foo
      <% end %>
    FILE

    it { expect(linter_errors).to eq [] }
  end

  context 'statements with partial block expression is processed' do
    let(:file) { <<~FILE }
      <% banned_method.each do %>
        foo
      <% end %>
    FILE

    it { expect(linter_errors).to eq [arbitrary_error_message] }
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

    it { expect(linter_errors).to eq [arbitrary_error_message(line: 4)] }
  end

  context 'code is aligned to the column matching start of erb tag' do
    let(:linter_config) do
      {
        only: ['Layout/AlignParameters'],
        AllCops: {
          TargetRubyVersion: '2.3',
        },
        'Layout/AlignParameters': {
          Enabled: true,
          EnforcedStyle: 'with_fixed_indentation',
          SupportedStyles: %w[with_first_parameter with_fixed_indentation],
          IndentationWidth: nil,
        }
      }.deep_stringify_keys
    end

    context 'when alignment is correct' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
          checked: true %>
      FILE

      it { expect(linter_errors).to eq [] }
    end

    context 'when alignment is incorrect' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
              checked: true %>
      FILE

      it do
        expect(linter_errors).to eq [
          {
            line: 2,
            message:
              "Layout/AlignParameters: Use one level of indentation for "\
              "parameters following the first line of a multi-line method call."
          }
        ]
      end
    end

    context 'correct alignment with html preceeding erb' do
      let(:file) { <<~FILE }
        <div><a><br><% ui_helper :foo,
                      checked: true %>
      FILE

      it { expect(linter_errors).to eq [] }
    end
  end

  private

  def arbitrary_error_message(line: 1)
    {
      message: "ErbLint/ArbitraryRule: An arbitrary rule has been violated.",
      line: line
    }
  end
end
