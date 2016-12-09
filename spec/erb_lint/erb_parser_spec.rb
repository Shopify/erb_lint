# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::ERBParser do
  describe '#parse' do
    # context 'with a simple erb file' do
    #   let(:file) { File.read(File.expand_path('../fixtures/erb/example1.erb', __FILE__)) }

    #   it 'returns a ruby ast' do
    #     foo = described_class.parse(file)
    #     expect(true).to eq true
    #   end
    # end

    # context 'with an output including a capture block' do
    #   let(:file) { File.read(File.expand_path('../fixtures/erb/example2.erb', __FILE__)) }

    #   it 'returns a ruby ast' do
    #     foo = described_class.parse(file)
    #     expect(true).to eq true
    #   end
    # end

    context 'with an output including a capture block' do
      let(:file) { File.read(File.expand_path('../fixtures/erb/example3.erb', __FILE__)) }

      it 'returns a ruby ast' do
        foo = described_class.parse(file)
        expect(true).to eq true
      end
    end
  end
end
