# frozen_string_literal: true

require "spec_helper"

describe ERBLint::ProcessedSource do
  let(:file) { <<~FILE }
    <div>
      <script type="text/javascript">
        var x = 1;
      </script>
      <input type="text" name="foo">
      <%= helper_method %>
      <% if condition %>
        <span><%= value %></span>
      <% end %>
    </div>
  FILE
  let(:processed_source) { described_class.new("file.html.erb", file) }

  describe "#erb_nodes" do
    it "returns an array of erb nodes" do
      expect(processed_source.erb_nodes).to(be_an(Array))
      expect(processed_source.erb_nodes).not_to(be_empty)
    end

    it "returns the same object on subsequent calls" do
      expect(processed_source.erb_nodes).to(equal(processed_source.erb_nodes))
    end

    it "matches ast.descendants(:erb)" do
      expect(processed_source.erb_nodes).to(eq(processed_source.ast.descendants(:erb).to_a))
    end
  end

  describe "#tag_nodes" do
    it "returns an array of tag nodes" do
      expect(processed_source.tag_nodes).to(be_an(Array))
      expect(processed_source.tag_nodes).not_to(be_empty)
    end

    it "returns the same object on subsequent calls" do
      expect(processed_source.tag_nodes).to(equal(processed_source.tag_nodes))
    end

    it "matches parser.nodes_with_type(:tag)" do
      expect(processed_source.tag_nodes).to(eq(processed_source.parser.nodes_with_type(:tag).to_a))
    end
  end
end
