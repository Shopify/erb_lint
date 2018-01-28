# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::RunnerConfig do
  describe '.default' do
    subject(:runner_config) { described_class.default }

    it 'returns expected class' do
      expect(subject.class).to be(described_class)
    end

    it 'has FinalNewline enabled' do
      expect(subject.for_linter('FinalNewline').enabled?).to be(true)
    end
  end

  context 'with custom config' do
    let(:runner_config) { described_class.new(config_hash) }

    describe '#to_hash' do
      subject { runner_config.to_hash }

      context 'with empty hash' do
        let(:config_hash) { {} }

        it { expect(subject).to eq({}) }
      end

      context 'with custom data' do
        let(:config_hash) { { foo: true } }

        it { expect(subject).to eq('foo' => true) }
      end
    end

    describe '#for_linter' do
      subject { runner_config.for_linter(linter) }

      class MyCustomLinter < ERBLint::Linter
        class MySchema < ERBLint::LinterConfig
          property :my_option
        end
        self.config_schema = MySchema
      end

      before do
        allow(ERBLint::LinterRegistry).to receive(:linters)
          .and_return([ERBLint::Linters::FinalNewline, MyCustomLinter])
      end

      context 'with string argument' do
        let(:linter) { 'MyCustomLinter' }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { 'my_option' => 'custom value' } } } }

        it { expect(subject.class).to eq(MyCustomLinter::MySchema) }
        it { expect(subject['my_option']).to eq('custom value') }
      end

      context 'with class argument' do
        let(:linter) { MyCustomLinter }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { my_option: 'custom value' } } } }

        it { expect(subject.class).to eq(MyCustomLinter::MySchema) }
      end

      context 'with argument that isnt a string and does not inherit from Linter' do
        let(:linter) { Object }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { my_option: 'custom value' } } } }

        it { expect { subject }.to raise_error(ArgumentError, "expected String or linter class") }
      end

      context 'for linter not present in config hash' do
        let(:linter) { 'FinalNewline' }
        let(:config_hash) {}

        it { expect(subject.class).to eq(ERBLint::Linters::FinalNewline::ConfigSchema) }
        it 'fills linter config with defaults from schema' do
          expect(subject.to_hash).to eq("enabled" => false, "exclude" => [], "present" => true)
        end
        it 'is disabled by default' do
          expect(subject.enabled?).to eq(false)
        end
      end

      context 'when global excludes are specified' do
        let(:linter) { MyCustomLinter }
        let(:config_hash) do
          {
            linters: {
              'MyCustomLinter' => { exclude: ['foo/bar.rb'] }
            },
            exclude: [
              '**/node_modules/**'
            ]
          }
        end

        it 'excluded files are merged' do
          expect(subject.exclude).to eq(['foo/bar.rb', '**/node_modules/**'])
        end
      end
    end

    describe '#merge' do
      let(:first_config) { described_class.new(foo: 1) }
      let(:second_config) { described_class.new(bar: 2) }
      subject { first_config.merge(second_config) }

      context 'creates a new object' do
        it { expect(subject.class).to be(described_class) }
        it { expect(subject).to_not be(first_config) }
        it { expect(subject).to_not be(second_config) }
      end

      context 'new object has keys from both configs' do
        it { expect(subject.to_hash).to eq('foo' => 1, 'bar' => 2) }
      end

      context 'second object overwrites keys from first object' do
        let(:second_config) { described_class.new(foo: 42) }
        it { expect(subject.to_hash).to eq('foo' => 42) }
      end

      context 'performs a deep merge' do
        let(:first_config) { described_class.new(nested: { foo: 1 }) }
        let(:second_config) { described_class.new(nested: { bar: 2 }) }
        it { expect(subject.to_hash).to eq('nested' => { 'foo' => 1, 'bar' => 2 }) }
      end
    end

    describe '#merge!' do
      let(:first_config) { described_class.new(foo: 1) }
      let(:second_config) { described_class.new(bar: 2) }
      subject { first_config.merge!(second_config) }

      context 'returns first object' do
        it { expect(subject).to be(first_config) }
      end

      context 'first object has keys from both configs' do
        it { expect(subject.to_hash).to eq('foo' => 1, 'bar' => 2) }
      end

      context 'second object overwrites keys from first object' do
        let(:second_config) { described_class.new(foo: 42) }
        it { expect(subject.to_hash).to eq('foo' => 42) }
      end

      context 'performs a deep merge' do
        let(:first_config) { described_class.new(nested: { foo: 1 }) }
        let(:second_config) { described_class.new(nested: { bar: 2 }) }
        it { expect(subject.to_hash).to eq('nested' => { 'foo' => 1, 'bar' => 2 }) }
      end
    end
  end
end
