# frozen_string_literal: true

require "spec_helper"
require "spec_utils"

describe ERBLint::Linters::NoLinkToBack do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }
  let(:offenses) { linter.offenses }

  describe "offenses" do
    subject { offenses }

    context "when file has link_to :back" do
      let(:file) do
        <<~ERB
          <%= link_to '戻る', :back %>
        ERB
      end
      before { linter.run(processed_source) }
      it do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(
          eq("Don't use :back option in link_to method. It potentially causes XSS attack by HTTP Referer pollution."),
        )
      end
    end

    context "when file has link_to :back with block" do
      let(:file) do
        <<~ERB
          <%= link_to :back do %>
            <span>test</span>
          <% end %>
        ERB
      end
      before { linter.run(processed_source) }
      it do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(
          eq("Don't use :back option in link_to method. It potentially causes XSS attack by HTTP Referer pollution."),
        )
      end
    end

    context "when file has link_to_unless :back" do
      let(:file) { "<%= link_to_unless true, '戻る', :back %>" }
      before { linter.run(processed_source) }

      it do
        expect(subject.size).to(eq(1))
        expect(subject.first.message).to(eq(
          "Don't use :back option in link_to_unless method. " \
            "It potentially causes XSS attack by HTTP Referer pollution.",
        ))
      end
    end

    context ":back is used as name" do
      let(:file) do
        <<~ERB
          <%= link_to :back, '#' %>
        ERB
      end
      before { linter.run(processed_source) }
      it do
        expect(subject.size).to(eq(0))
      end
    end
  end
end
