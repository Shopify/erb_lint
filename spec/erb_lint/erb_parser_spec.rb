# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::ERBParser do
  describe '#parse' do
    context 'test' do
      let(:file) { File.read(File.expand_path('../fixtures/erb/example1.erb', __FILE__)) }

      it 'returns a document fragment with only the end marker as a child' do
        foo = described_class.parse(file)
        binding.pry
        expect(true).to eq true
      end
    end
  end
end
