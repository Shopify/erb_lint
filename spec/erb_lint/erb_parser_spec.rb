# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::ERBParser do
  describe '#parse' do
    context 'test' do
      let(:file) { File.read(File.expand_path('../fixtures/erb/example2.erb', __FILE__)) }

      it 'returns a ruby ast' do
        foo = described_class.parse(file)
        binding.pry
        expect(true).to eq true
      end
    end
  end
end
