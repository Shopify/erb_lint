# frozen_string_literal: true

require "spec_helper"
require "fakefs"
require "fakefs/spec_helpers"

FakeFS.deactivate!
require "erb_lint/rake_task"
FakeFS.activate!

RSpec.describe(ERBLint::RakeTask) do
  subject(:task) { described_class.new(cli: cli) }

  let(:cli) { instance_spy ERBLint::CLI }

  before { Rake::Task.clear }

  describe "#initialize" do
    it "logs error" do
      task
      expectation = proc { Rake::Task["erb_lint"].execute }

      expect(&expectation).to(output(/Running ERB Lint.../).to_stderr)
    end

    it "executes with default name and arguments" do
      task
      Rake::Task["erb_lint"].execute

      expect(cli).to(have_received(:run).with(["--lint-all"]))
    end

    it "executes with default name and custom arguments" do
      described_class.new(cli: cli) { ["--autocorrect", "."] }
      Rake::Task["erb_lint"].execute

      expect(cli).to(have_received(:run).with(["--autocorrect", "."]))
    end

    it "executes with custom name and arguments" do
      described_class.new(:erb_auto_correct, cli: cli) { ["--autocorrect", "."] }
      Rake::Task["erb_auto_correct"].execute

      expect(cli).to(have_received(:run).with(["--autocorrect", "."]))
    end
  end
end
