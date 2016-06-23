# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Parser do
  describe '#parse' do
    context 'when the file is empty' do
      let(:file) { '' }

      it 'returns a document fragment with only the end marker as a child' do
        expect(described_class.parse(file).class).to eq Nokogiri::XML::DocumentFragment
        expect(described_class.parse(file).children.size).to eq 1
        expect(described_class.parse(file).child.name).to eq ERBLint::Parser::END_MARKER_NAME
      end
    end

    context 'when the file has erb tags' do
      context 'when the erb tags only contain whitespace' do
        context 'when the erb tags are code execution tags' do
          let(:file) { '<% %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags are code evaluation tags' do
          let(:file) { '<%= %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags trim the following line break' do
          let(:file) { '<% -%>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags are comment tags' do
          let(:file) { '<%# %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags are inside double quotes' do
          let(:file) { '"<% %>"' }

          it 'returns a text node consisting of double quotes containing 5 spaces' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq '"     "'
          end
        end

        context 'when the erb tags are inside single quotes' do
          let(:file) { "'<% %>'" }

          it 'returns a text node consisting of single quotes containing 5 spaces' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq "'     '"
          end
        end
      end

      context 'when the erb tags contain content' do
        context 'when the erb tags contain content on one line' do
          let(:file) { '<% this is some content %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
            expect(described_class.parse(file).child.text.scan(/\n/).size).to eq 0
          end
        end

        context 'when the erb tags contain multiple lines' do
          let(:file) { "<% \n \n \n %>" }

          it 'returns a text node consiting only of whitespace and three newlines' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
            expect(described_class.parse(file).child.text.scan(/\n/).size).to eq 3
          end
        end

        context 'when the erb tags contain content on multiple lines' do
          let(:file) { <<~FILE.chomp }
            <%
              line1
              line2
              line3
            %>
          FILE

          it 'returns a text node consiting only of whitespace and four newlines' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
            expect(described_class.parse(file).child.text.scan(/\n/).size).to eq 4
          end
        end

        context 'when the erb tags contain an erb start tag' do
          let(:file) { '<% <% %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags appear after an erb start tag literal' do
          let(:file) { '<%% <% has literal %>' }

          it 'returns a text node consisting only of an erb start tag literal and whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq '<%%'
          end
        end

        context 'when the erb tags contain an erb end tag literal' do
          let(:file) { '<% has literal %%> %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags are separated in strings' do
          let(:file) { "'<%=' + within_string + '%>'" }

          it 'returns a text node consisting of single quotes containing 26 spaces' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq "'                          '"
          end
        end

        context 'when the erb tags contain an invalid string with double quotes' do
          let(:file) { '<% " %>' }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end

        context 'when the erb tags contain an invalid string with single quotes' do
          let(:file) { "<% ' %>" }

          it 'returns a text node consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.text?).to be_truthy
            expect(described_class.parse(file).child.text.strip).to eq ''
          end
        end
      end

      context 'when the erb tags are inside of another element' do
        context 'when the erb tags represent a child of the element' do
          let(:file) { <<~FILE.chomp }
            <div>
              <% within element content %>
            </div>
          FILE

          it 'returns a div node with a text node consisting only of whitespace as its child' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.name).to eq 'div'
            expect(described_class.parse(file).child.children.size).to eq 1
            expect(described_class.parse(file).child.child.text?).to be_truthy
            expect(described_class.parse(file).child.child.text.strip).to eq ''
          end
        end

        context 'when the erb tags are within an attribute of the element' do
          let(:file) { <<~FILE.chomp }
            <div class="<% within element attribute %>"></div>
          FILE

          it 'returns a div node with a class atribute value consisting only of whitespace' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.name).to eq 'div'
            expect(described_class.parse(file).child['class'].strip).to eq ''
          end
        end

        context 'when the erb tags are within the attribute list of the element' do
          let(:file) { <<~FILE.chomp }
            <div <% within element attribute list %>></div>
          FILE

          it 'returns a div node with no attributes or children' do
            expect(described_class.parse(file).children.size).to eq 2
            expect(described_class.parse(file).child.name).to eq 'div'
            expect(described_class.parse(file).child.attributes.size).to eq 0
            expect(described_class.parse(file).child.children.size).to eq 0
          end
        end
      end

      context 'when the erb tags are not closed properly' do
        let(:file) { '<% unclosed ' }

        it 'raises an unclosed erb tag error' do
          expect { described_class.parse(file) }.to raise_error(described_class::ParseError, 'Unclosed ERB tag found.')
        end
      end
    end

    context 'when tags are not properly closed' do
      let(:file) { <<~FILE.chomp }
        <div>
      FILE

      it 'raises a general parsing error' do
        expect { described_class.parse(file) }.to raise_error(
          described_class::ParseError,
          'File could not be successfully parsed. Ensure all tags are properly closed.'
        )
      end
    end
  end

  describe '#file_is_empty?' do
    let(:file_tree) { described_class.parse(file) }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'returns true' do
        expect(described_class.file_is_empty?(file_tree)).to be_truthy
      end
    end

    context 'when the file has content' do
      let(:file) { 'content' }

      it 'returns false' do
        expect(described_class.file_is_empty?(file_tree)).to be_falsy
      end
    end

    context 'when the file contains only a newline' do
      let(:file) { "\n" }

      it 'returns false' do
        expect(described_class.file_is_empty?(file_tree)).to be_falsy
      end
    end
  end
end
