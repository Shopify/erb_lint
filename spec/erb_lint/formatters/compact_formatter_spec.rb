# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Formatters::CompactFormatter do
  describe '.format' do
    subject { described_class.new(offenses, filename, false).format }

    let(:filename) { 'app/views/users/show.html.erb' }
    let(:offenses) do
      [
        instance_double(ERBLint::Offense,
                        message: 'Extra space detected where there should be no space.',
                        line_number: 61,
                        column: 10),
        instance_double(ERBLint::Offense,
                        message: 'Remove multiple trailing newline at the end of the file.',
                        line_number: 125,
                        column: 1),
      ]
    end

    it "generates formatted offenses" do
      expect(subject).to(eq([
        'app/views/users/show.html.erb:61:10: Extra space detected where there should be no space.',
        'app/views/users/show.html.erb:125:1: Remove multiple trailing newline at the end of the file.',
      ]))
    end
  end
end
