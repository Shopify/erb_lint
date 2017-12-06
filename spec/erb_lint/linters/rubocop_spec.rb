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

  context 'supports loading nested config' do
    let(:linter_config) do
      {
        only: ['ErbLint/ArbitraryRule'],
        inherit_from: 'custom_rubocop.yml',
        AllCops: {
          TargetRubyVersion: '2.3',
        },
      }.deep_stringify_keys
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
