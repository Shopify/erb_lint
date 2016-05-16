require 'spec_helper'

describe ERBLint::Runner do
  let(:runner) { described_class.new(config) }

  before do
    allow(ERBLint::LinterRegistry).to receive(:linters)
                                  .and_return([ERBLint::Linter::FakeLinter1,
                                               ERBLint::Linter::FakeLinter2])
  end

  class ERBLint::Linter::FakeLinter1 < ERBLint::Linter; def initialize(_config) end end
  class ERBLint::Linter::FakeLinter2 < ERBLint::Linter; def initialize(_config) end end

  describe '#run' do
    let(:file) { 'DummyFileContent' }
    subject { runner.run(file) }

    fake_linter_1_errors = ['FakeLinter1DummyErrors']
    fake_linter_2_errors = ['FakeLinter2DummyErrors']

    before do
      allow_any_instance_of(ERBLint::Linter::FakeLinter1).to receive(:lint_file).with(file).and_return fake_linter_1_errors
      allow_any_instance_of(ERBLint::Linter::FakeLinter2).to receive(:lint_file).with(file).and_return fake_linter_2_errors
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
              linter: ERBLint::Linter::FakeLinter1,
              errors: fake_linter_1_errors
            },
            {
              linter: ERBLint::Linter::FakeLinter2,
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
              linter: ERBLint::Linter::FakeLinter1,
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
  end
end