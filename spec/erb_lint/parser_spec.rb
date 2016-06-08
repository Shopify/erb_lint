# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Parser do
  describe '#remove_escaped_erb_tags' do
    # Test cases
    # _erb_ ... _/erb_
  end

  describe '#parse' do
    # Test cases
    # <% %>
    # <%= %>
    # <% -%>
    # <%# %>
    # '<% %>'
    # "<% %>"
    # <% ' ' %>
    # <% " " %>
    # " "
    # " ' "
    # " ' ' "
    # " ' ' ' "
    # ' '
    # ' " '
    # ' " " '
    # ' " " " '
    # " " "
    # ' ' '
    # <div>

    context 'when the file is empty' do
      let(:file) { '' }

      it 'returns a document fragment with only the end marker as a child' do
        expect(described_class.parse(file).children.size).to eq 1
        expect(described_class.parse(file).child.name).to eq ERBLint::Parser::END_MARKER_NAME
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
