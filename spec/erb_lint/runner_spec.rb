# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Runner do
  let(:runner) { described_class.new(config) }

  before do
    allow(ERBLint::LinterRegistry).to receive(:linters)
      .and_return([ERBLint::Linters::FakeLinter1,
                   ERBLint::Linters::FakeLinter2,
                   ERBLint::Linters::FinalNewline])
  end

  module ERBLint
    module Linters
      class FakeLinter1 < Linter
        def initialize(_config) end
      end
      class FakeLinter2 < Linter
        def initialize(_config) end
      end
    end
  end

  describe '#run' do
    let(:file) { 'DummyFileContent' }
    let(:filename) { 'somefolder/otherfolder/dummyfile.html.erb' }
    subject { runner.run(filename, file) }

    fake_linter_1_errors = ['FakeLinter1DummyErrors']
    fake_linter_2_errors = ['FakeLinter2DummyErrors']
    fake_final_newline_errors = ['FakeFinalNewlineDummyErrors']

    before do
      allow_any_instance_of(ERBLint::Linters::FakeLinter1).to receive(:lint_file)
        .with(file).and_return fake_linter_1_errors
      allow_any_instance_of(ERBLint::Linters::FakeLinter2).to receive(:lint_file)
        .with(file).and_return fake_linter_2_errors
      allow_any_instance_of(ERBLint::Linters::FinalNewline).to receive(:lint_file)
        .with(file).and_return fake_final_newline_errors
    end

    context 'when all linters are enabled' do
      let(:config) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => true }
          }
        }
      end

      it 'returns each linter with their errors' do
        expect(subject).to eq [
          {
            linter_name: 'FakeLinter1',
            errors: fake_linter_1_errors
          },
          {
            linter_name: 'FakeLinter2',
            errors: fake_linter_2_errors
          }
        ]
      end
    end

    context 'when only some linters are enabled' do
      let(:config) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => false }
          }
        }
      end

      it 'returns only enabled linters with their errors' do
        expect(subject).to eq [
          {
            linter_name: 'FakeLinter1',
            errors: fake_linter_1_errors
          }
        ]
      end
    end

    context 'when all linters are disabled' do
      let(:config) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => false },
            'FakeLinter2' => { 'enabled' => false }
          }
        }
      end

      it 'returns no linters' do
        expect(subject).to be_empty
      end
    end

    context 'when all linters exclude the file' do
      let(:config) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => true, 'exclude' => ['**/otherfolder/**'] },
            'FakeLinter2' => { 'enabled' => true, 'exclude' => ['somefolder/**.html.erb'] }
          }
        }
      end

      it 'returns no linters' do
        expect(subject).to be_empty
      end
    end

    context 'when the config has no linters' do
      let(:config) { {} }

      it 'returns default linters with their errors' do
        expect(subject).to eq [
          {
            linter_name: 'FinalNewline',
            errors: fake_final_newline_errors
          }
        ]
      end
    end

    context 'when the config is nil' do
      let(:config) { nil }

      it 'returns default linters with their errors' do
        expect(subject).to eq [
          {
            linter_name: 'FinalNewline',
            errors: fake_final_newline_errors
          }
        ]
      end
    end
  end
end
