# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Parser do
  describe '#remove_escaped_erb_tags' do
    # Test cases
    # _erb_ ... _/erb_
  end

  describe '#parse' do
    context 'when the file is empty' do
      let(:file) { '' }

      it 'returns a document fragment with only the end marker as a child' do
        expect(described_class.parse(file).children.size).to eq 1
        expect(described_class.parse(file).child.name).to eq ERBLint::Parser::END_MARKER_NAME
      end
    end

    context 'when the file has erb tags' do
      context 'when the erb tags are code execution tags' do
        let(:file) { '<% %>' }

        it 'returns a document fragment with an empty erb tag' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to start_with ' '
        end
      end

      context 'when the erb tags are code evaluation tags' do
        let(:file) { '<%= %>' }

        it 'returns a document fragment with an erb tag beginning with =' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to start_with '='
        end
      end

      context 'when the erb tags trim the following line break' do
        let(:file) { '<% -%>' }

        it 'returns a document fragment with an erb tag ending with -' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to end_with '-'
        end
      end

      context 'when the erb tags are comment tags' do
        let(:file) { '<%# %>' }

        it 'returns a document fragment with an erb tag beginning with #' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to start_with '#'
        end
      end

      context 'when the erb tags are inside double quotes' do
        let(:file) { '"<% %>"' }

        it 'returns a document fragment with escaped erb tags inside a text node' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'text'
          expect(described_class.parse(file).child.text).to eq '"_erb_ _/erb_"'
        end
      end

      context 'when the erb tags are inside single quotes' do
        let(:file) { "'<% %>'" }

        it 'returns a document fragment with escaped erb tags inside a text node' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'text'
          expect(described_class.parse(file).child.text).to eq "'_erb_ _/erb_'"
        end
      end

      context 'when the erb tags contain an invalid string with double quotes' do
        let(:file) { '<% " %>' }

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end

        it 'returns a document fragment with the double quote inside the erb tag' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to eq ' " '
        end
      end

      context 'when the erb tags contain an invalid string with single quotes' do
        let(:file) { "<% ' %>" }

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end

        it 'returns a document fragment with the single quote inside the erb tag' do
          expect(described_class.parse(file).children.size).to eq 2
          expect(described_class.parse(file).child.name).to eq 'erb'
          expect(described_class.parse(file).child.text).to eq " ' "
        end
      end
    end

    context 'when the file contains quotes' do
      context 'when the file has two double quotes' do
        let(:file) { <<~'FILE' }
          " "
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has three double quotes' do
        let(:file) { <<~'FILE' }
          " " "
        FILE

        it 'raises an unclosed string error' do
          expect{described_class.parse(file)}.to raise_error(described_class::ParsingError, 'Unclosed string found.')
        end
      end

      context 'when the file has an escaped double quote within double quotes' do
        let(:file) { <<~'FILE' }
          " \" "
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has one single quote within double quotes' do
        let(:file) { <<~'FILE' }
          " ' "
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has two single quotes within double quotes' do
        let(:file) { <<~'FILE' }
          " ' ' "
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has three single quotes within double quotes' do
        let(:file) { <<~'FILE' }
          " ' ' ' "
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has two single quotes' do
        let(:file) { <<~'FILE' }
          ' '
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has three single quotes' do
        let(:file) { <<~'FILE' }
          ' ' '
        FILE

        it 'raises an unclosed string error' do
          expect{described_class.parse(file)}.to raise_error(described_class::ParsingError, 'Unclosed string found.')
        end
      end

      context 'when the file has an escaped single quote within single quotes' do
        let(:file) { <<~'FILE' }
          ' \' '
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has one double quote within single quotes' do
        let(:file) { <<~'FILE' }
          ' " '
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has two double quotes within single quotes' do
        let(:file) { <<~'FILE' }
          ' " " '
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has three double quotes within single quotes' do
        let(:file) { <<~'FILE' }
          ' " " " '
        FILE

        it 'does not raise an error' do
          expect{described_class.parse(file)}.to_not raise_error
        end
      end

      context 'when the file has overlapping quotes' do
        let(:file) { <<~'FILE' }
          " ' " '
        FILE

        it 'raises an unclosed string error' do
          expect{described_class.parse(file)}.to raise_error(described_class::ParsingError, 'Unclosed string found.')
        end

        let(:file) { <<~'FILE' }
          ' " ' "
        FILE

        it 'raises an unclosed string error' do
          expect{described_class.parse(file)}.to raise_error(described_class::ParsingError, 'Unclosed string found.')
        end
      end
    end

    context 'when the file is full of edge cases' do
      let(:file) { <<~'FILE' }
        <div class='a <%= something if " adwiawd "%> a-b--c'
             name="foo">
          <h1>Fleeb</h1>
        </div>
        <h3 class="d-e__f__g"><%= section %></h3>
        <ul class="h-i j-k--<%= color %>">
          <div class="l-m__n o-p__q--<%= color_str %> <%= "r-s__t--u-v" if i >= something %>">
          </div>
        </ul>
      FILE

      it 'returns a valid tree structure representing the file' do
        expect(described_class.parse(file).class).to eq Nokogiri::XML::DocumentFragment
      end
    end
  end
end
