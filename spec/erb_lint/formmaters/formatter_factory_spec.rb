# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Formatters::FormatterFactory do
  describe '#build' do
    context 'with available formatters' do
      formatters = described_class::AVAILABLE_FORMATTERS
      formatters.each do |format, expected|
        options = { format: format }
        it "returns #{expected} when format is #{format}" do
          expect(described_class.build(options)).to(be_a(expected))
        end
      end
    end
    context 'with missing or unrecognized format' do
      it "returns the default formatter" do
        expect(described_class.build(format: :unrecognized)).to(be_a(ERBLint::Formatters::DefaultFormatter))
      end
    end
  end
end
