# frozen_string_literal: true

require "spec_helper"

describe ERBLint::Utils::InlineConfigs do
  let(:utils) { described_class }

  context "rule_disable_comment_for_lines?" do
    it "true when lines contain a erb_lint:disable comment for rule in ERB" do
      offending_lines = '<a href="#"></a><%# erb_lint:disable AnchorRule %>'
      expect(utils.rule_disable_comment_for_lines?("AnchorRule", offending_lines)).to(be(true))
    end

    it "supports both erb_lint and erblint naming" do
      offending_lines = '<a href="#"></a><%# erb_lint:disable AnchorRule %>'
      expect(utils.rule_disable_comment_for_lines?("AnchorRule", offending_lines)).to(be(true))
    end

    it "true lines when lines contain a erb_lint:disable comment for rule in Ruby comment" do
      offending_lines = '<%
			button = {
					role: "img" # erb_lint:disable IncorrectRoleRule
			}
			%>'
      expect(utils.rule_disable_comment_for_lines?("IncorrectRoleRule", offending_lines)).to(be(true))
    end

    it "true lines when lines contain matching erb_lint:disable comment for rule in Ruby comment" do
      offending_lines = '<%
			button = {
					role: "img" # erb_lint:disable IncorrectRoleRule, AnotherRule
			}
			%>'
      expect(utils.rule_disable_comment_for_lines?("AnotherRule", offending_lines)).to(be(true))
    end

    it "false when lines contain erb_lint:disable comment that does not contain specified rule" do
      offending_lines = '<a href="#"></a><%# erb_lint:disable AnchorRule %>'
      expect(utils.rule_disable_comment_for_lines?("AnotherRule", offending_lines)).to(be(false))
    end
  end

  context "disabled_rules" do
    it "returns rule in ERB" do
      lines = '<a href="#"></a><%# erb_lint:disable AnchorRule %>'
      expect(utils.disabled_rules(lines)).to(eq("AnchorRule"))
    end

    it "returns rules in ERB" do
      lines = '<a href="#"></a><%# erb_lint:disable Rule1, Rule2, Rule3 %>'
      expect(utils.disabled_rules(lines)).to(eq("Rule1, Rule2, Rule3"))
    end
  end
end
