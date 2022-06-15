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
      :color_field_tag,
      :email_field_tag,
      :text_field_tag,
      :utf8_enforcer_tag,
      :month_field_tag,
      :number_field_tag,
      :password_field_tag,
      :search_field_tag,
      :telephone_field_tag,
      :time_field_tag,
      :url_field_tag,
      :week_field_tag,
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
            s + "<%= " + helper.to_s + ' autocomplete: "foo" do %>'
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
            s + "<%= " + helper.to_s + " do %>"
          end
        }
      FILE

      it do
        expect(subject).to(eq([
          build_offense(7..30, form_helper_message),
          build_offense(31..55, form_helper_message),
          build_offense(56..80, form_helper_message),
          build_offense(81..104, form_helper_message),
          build_offense(105..131, form_helper_message),
          build_offense(132..156, form_helper_message),
          build_offense(157..182, form_helper_message),
          build_offense(183..210, form_helper_message),
          build_offense(211..236, form_helper_message),
          build_offense(237..265, form_helper_message),
          build_offense(266..289, form_helper_message),
          build_offense(290..312, form_helper_message),
          build_offense(313..336, form_helper_message),
        ]))
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
