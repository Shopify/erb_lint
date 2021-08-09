# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Linters::RequireInputAutocomplete do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new(".") }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new("file.rb", file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  let(:form_helpers_requiring_autocomplete) do
    [
      :date_field_tag,
      :date_field,
      :color_field_tag,
      :color_field,
      :email_field_tag,
      :email_field,
      :text_field_tag,
      :text_field,
      :utf8_enforcer_tag,
      :month_field_tag,
      :month_field,
      :number_field_tag,
      :number_field,
      :password_field_tag,
      :password_field,
      :search_field_tag,
      :search_field,
      :telephone_field_tag,
      :telephone_field,
      :phone_field_tag,
      :phone_field,
      :time_field_tag,
      :time_field,
      :url_field_tag,
      :url_field,
      :week_field_tag,
      :week_field,
    ].freeze
  end
  let(:html_message) do
    "Input tag is missing an autocomplete attribute. If no autocomplete behaviour "\
    "is desired, use the value `off` or `nope`."
  end
  let(:form_helper_message) do
    "Input field helper is missing an autocomplete attribute. If no autocomplete "\
    "behaviour is desired, use the value `off` or `nope`."
  end
  before { linter.run(processed_source) }

  describe "pure HTML linting" do
    subject { offenses }

    context "when input type requires autocomplete attribute and it is present" do
      let(:file) { '<input type="email" autocomplete="foo">' }
      it { expect(subject).to(eq([])) }
    end

    context "when input type does not require autocomplete attribute and it is not present" do
      let(:file) { '<input type="bar">' }
      it { expect(subject).to(eq([])) }
    end

    context "when input type requires autocomplete attribute and it is not present" do
      let(:file) { '<input type="email">' }
      it { expect(subject).to(eq([build_offense(1..5, html_message)])) }
    end
  end

  describe "input field helpers linting" do
    subject { offenses }

    context "usage of field helpers with autocomplete value" do
      let(:file) { <<~FILE }
        <br />
        #{
          form_helpers_requiring_autocomplete.inject("") do |s, helper|
            s + "<%= " + helper.to_s + ' autocomplete: "foo" %>'
          end
        }
        FILE

      it { expect(subject).to(eq([])) }
    end

    context "usage of field helpers without autocomplete value" do
      let(:file) { <<~FILE }
        <br />
        #{
          form_helpers_requiring_autocomplete.inject("") do |s, helper|
            s + "<%= " + helper.to_s + " %>"
          end
        }
        FILE

      it do
        form_helpers_requiring_autocomplete.each do |helper|
          tag = "<%= #{helper} %>"
          index = processed_source.file_content.index(tag)

          expect(subject).to(
            include(
              build_offense(
                Range.new(index, index + tag.length - 1),
                form_helper_message
              )
            )
          )
        end
      end
    end
  end

  private

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message
    )
  end
end
