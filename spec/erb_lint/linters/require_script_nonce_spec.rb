# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::RequireScriptNonce do
  let(:linter_config) { described_class.config_schema.new }
  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }
  let(:html_nonce_message) { "Missing a nonce attribute. Use request.content_security_policy_nonce" }
  let(:tag_helper_nonce_message) { "Missing a nonce attribute. Use nonce: true" }

  subject { linter.offenses }

  before { linter.run(processed_source) }

  describe "Pure HTML Linting" do
    let(:file) { "<script #{mime_type} #{nonce}>" }
    let(:mime_type) { nil }

    context "when nonce is present" do
      let(:nonce) { 'nonce="whatever"' }

      context "when MIME type is text/javascript" do
        let(:mime_type) { 'type="text/javascript"' }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end

      context "when MIME type is application/javascript" do
        let(:mime_type) { 'type="application/javascript"' }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end

      context "when MIME type is not specificed" do
        let(:mime_type) { nil }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end

      context "when MIME type is not text/javascript" do
        let(:mime_type) { 'type="text/whatever"' }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end

      context "when MIME type is not application/javascript" do
        let(:mime_type) { 'type="application/whatever"' }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end
    end

    context "when nonce has no value" do
      let(:nonce) { "nonce" }

      context "when MIME type is text/javascript" do
        let(:mime_type) { 'type="text/javascript"' }

        it "builds an offense for a HTML script tag with a missing nonce" do
          expect(subject).to(eq([
            build_offense(1..6, html_nonce_message),
          ]))
        end
      end

      context "when MIME type is application/javascript" do
        let(:mime_type) { 'type="application/javascript"' }

        it "builds an offense for a HTML script tag with a missing nonce" do
          expect(subject).to(eq([
            build_offense(1..6, html_nonce_message),
          ]))
        end
      end

      context "when MIME type is not specified" do
        let(:mime_type) { nil }

        it "builds an offense for a HTML script tag with a missing nonce" do
          expect(subject).to(eq([
            build_offense(1..6, html_nonce_message),
          ]))
        end
      end

      context "when MIME type is not text/javascript or application/javascript" do
        let(:mime_type) { 'type="text/whatever"' }

        it "passes the nonce check" do
          expect(subject).to(eq([]))
        end
      end
    end

    context "when nonce is not present" do
      let(:nonce) { nil }

      it "builds an offense for a HTML script tag with a missing nonce" do
        expect(subject).to(eq([
          build_offense(1..6, html_nonce_message),
        ]))
      end
    end
  end

  describe "Javascript helper tags linting" do
    context "usage of javascript_tag helper without nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_tag do %>
      FILE

      it "builds an offense for a Rails helper script tag with a missing nonce" do
        expect(subject).to(eq([build_offense(7..30, tag_helper_nonce_message)]))
      end
    end

    context "usage of javascript_include_tag helper without nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_include_tag "script" %>
      FILE

      it "builds an offense for a Rails helper script tag with a missing nonce" do
        expect(subject).to(eq([build_offense(7..44, tag_helper_nonce_message)]))
      end
    end

    context "usage of javascript_pack_tag helper without nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_pack_tag "script" %>
      FILE

      it "builds an offense for a Rails helper script tag with a missing nonce" do
        expect(subject).to(eq([build_offense(7..41, tag_helper_nonce_message)]))
      end
    end

    context "usage of javascript_tag helper with a nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_tag nonce: true do %>
      FILE

      it "passes the nonce check" do
        expect(subject).to(eq([]))
      end
    end

    context "usage of javascript_include_tag helper with a nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_include_tag "script", nonce: true %>
      FILE

      it "passes the nonce check" do
        expect(subject).to(eq([]))
      end
    end

    context "usage of javascript_pack_tag helper with a nonce" do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_pack_tag "script", nonce: true %>
      FILE

      it "passes the nonce check" do
        expect(subject).to(eq([]))
      end
    end
  end

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message
    )
  end
end
