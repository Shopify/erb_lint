# frozen_string_literal: true

require 'spec_helper'
require 'better_html'

describe ERBLint::Linters::ErbSafety do
  let(:linter_config) { described_class.config_schema.new }
  let(:better_html_config) do
    {
      javascript_safe_methods: ['to_json']
    }
  end
  let(:file_loader) { MockFileLoader.new(better_html_config) }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new(file) }
  subject(:offenses) { linter.offenses(processed_source) }

  class MockFileLoader
    def initialize(config)
      @config = config
    end

    def yaml(_filename)
      @config
    end
  end

  context 'interpolate a variable in js attribute' do
    let(:file) { <<~FILE }
      <a onclick="alert('<%= foo %>')">
    FILE

    it { expect(subject).to eq [unsafe_interpolate] }
  end

  context 'interpolate a variable in js attribute calling safe method' do
    let(:file) { <<~FILE }
      <a onclick="alert(<%= foo.to_json %>)">
    FILE

    it { expect(subject).to eq [] }
  end

  context 'interpolate a variable in js attribute calling safe method inside string interpolation' do
    let(:file) { <<~FILE }
      <a onclick="alert(<%= "hello \#{foo.to_json}" %>)">
    FILE

    it { expect(subject).to eq [] }
  end

  context 'html_safe in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%= foo.html_safe %>">
    FILE

    it { expect(subject).to eq [unsafe_html_safe] }
  end

  context 'html_safe in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <a onclick="<%= foo.to_json.html_safe %>">
    FILE

    it { expect(subject).to eq [unsafe_html_safe] }
  end

  context '<== in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%== foo %>">
    FILE

    it { expect(subject).to eq [unsafe_erb_interpolate] }
  end

  context '<== in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <div title="<%== foo.to_json %>">
    FILE

    it { expect(subject).to eq [unsafe_erb_interpolate] }
  end

  context 'raw in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%= raw foo %>">
    FILE

    it { expect(subject).to eq [unsafe_raw] }
  end

  context 'raw in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <div title="<%= raw foo.to_json %>">
    FILE

    it { expect(subject).to eq [unsafe_raw] }
  end

  context 'unsafe erb in <script>' do
    let(:file) { <<~FILE }
      <script>var foo = <%= unsafe %>;</script>
    FILE

    it { expect(subject).to eq [unsafe_javascript_tag_interpolate] }
  end

  context 'safe erb in <script>' do
    let(:file) { <<~FILE }
      <script>var foo = <%= unsafe.to_json %>;</script>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'safe erb in <script> when raw is present' do
    let(:file) { <<~FILE }
      <script>var foo = <%= raw unsafe.to_json %>;</script>
    FILE

    it { expect(subject).to eq [] }
  end

  context 'statements not allowed in <script> tags' do
    let(:file) { <<~FILE }
      <script><% if foo? %>var foo = 1;<% end %></script>
    FILE

    it { expect(subject).to eq [erb_statements_not_allowed] }
  end

  context 'changing better-html config file works' do
    let(:linter_config) do
      described_class.config_schema.new(
        'better_html_config' => '.better-html.yml'
      )
    end
    let(:file) { <<~FILE }
      <script><%= foobar %></script>
    FILE

    context 'with default config' do
      let(:better_html_config) { {} }
      it { expect(subject).to eq [unsafe_javascript_tag_interpolate] }
    end

    context 'with non-default config' do
      let(:better_html_config) { { javascript_safe_methods: ['foobar'] } }
      it { expect(subject).to eq [] }
    end

    context 'with string keys in config' do
      let(:better_html_config) { { 'javascript_safe_methods' => ['foobar'] } }
      it { expect(subject).to eq [] }
    end
  end

  private

  def unsafe_interpolate(line_range: 1..1)
    build_offense(line_range, "erb interpolation in javascript attribute must call '(...).to_json'")
  end

  def unsafe_html_safe(line_range: 1..1)
    build_offense(line_range, "erb interpolation with '<%= (...).html_safe %>' inside html attribute is never safe")
  end

  def unsafe_erb_interpolate(line_range: 1..1)
    build_offense(line_range, "erb interpolation with '<%==' inside html attribute is never safe")
  end

  def unsafe_raw(line_range: 1..1)
    build_offense(line_range, "erb interpolation with '<%= raw(...) %>' inside html attribute is never safe")
  end

  def unsafe_javascript_tag_interpolate(line_range: 1..1)
    build_offense(line_range, "erb interpolation in javascript tag must call '(...).to_json'")
  end

  def erb_statements_not_allowed(line_range: 1..1)
    build_offense(line_range, "erb statement not allowed here; did you mean '<%=' ?")
  end

  def build_offense(line_range, message)
    ERBLint::Offense.new(linter, line_range, message)
  end
end
