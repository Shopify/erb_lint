# frozen_string_literal: true

require "spec_helper"
require "erb_lint/cache"
require "fakefs"
require "fakefs/spec_helpers"

describe ERBLint::Cache do
  include FakeFS::SpecHelpers

  let(:linter_config) { ERBLint::LinterConfig.new }
  let(:cache) { described_class.new(linter_config) }
  let(:linted_file_path) { "app/components/elements/image_component/image_component.html.erb" }
  let(:checksum) { "835c15465bc22783257bdafb33acc2d78c29abaa" }
  let(:cache_dir) { ERBLint::Cache::CACHE_DIRECTORY }
  let(:rubocop_yml) { %(SpaceAroundErbTag:\n  Enabled: true\n) }
  let(:cache_file_content) do
    FakeFS.deactivate!
    content = File.read(File.expand_path("./spec/erb_lint/fixtures/cache_file_content"))
    FakeFS.activate!
    content
  end
  let(:linted_file_content) do
    FakeFS.deactivate!
    content = File.read(File.expand_path("./spec/erb_lint/fixtures/image_component.html.erb"))
    FakeFS.activate!
    content
  end

  around do |example|
    FakeFS do
      example.run
    end
  end

  before do
    FileUtils.mkdir_p(File.dirname(linted_file_path))
    File.write(linted_file_path, linted_file_content)

    FileUtils.mkdir_p(cache_dir)
    File.open(File.join(cache_dir, checksum), "wb") do |f|
      f.write(cache_file_content)
    end

    allow(::RuboCop::ConfigLoader).to(receive(:load_file).and_call_original)
    allow(::RuboCop::ConfigLoader).to(receive(:read_file).and_return(rubocop_yml))
  end

  describe "#get" do
    it "returns a cached lint result" do
      cache_result = cache.get(linted_file_path, cache_file_content)
      expect(cache_result.count).to(eq(2))
    end
  end

  describe "#[]=" do
    it "caches a lint result" do
      cache[linted_file_path] = cache_file_content
      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
    end
  end

  describe "#include?" do
    it "returns true if the cache includes the filename" do
      expect(cache.include?(linted_file_path)).to(be(true))
    end

    it "returns false if the cache does not include the filename" do
      expect(cache.include?("gibberish")).to(be(false))
    end
  end

  describe "#cache_dir_exists?" do
    it "returns true if the cache dir exists" do
      expect(cache.cache_dir_exists?).to(be(true))
    end
    it "returns false if the cache dir does not exist" do
      FileUtils.rm_rf(cache_dir)
      expect(cache.cache_dir_exists?).to(be(false))
    end
  end

  describe "#clear" do
    it "deletes the cache directory" do
      cache.clear
      expect(File.directory?(cache_dir)).to(be(false))
    end
  end

  describe "#prune" do
    it "skips prune if no cache hits" do
      allow(cache).to(receive(:hits).and_return([]))

      expect { cache.prune }.to(output(/Cache being created for the first time, skipping prune/).to_stdout)
    end

    it "does not prune actual cache hits" do
      cache.prune

      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
    end

    it "does not prune new cache results" do
      allow(cache).to(receive(:hits).and_return(["fake-hit"]))
      allow(cache).to(receive(:new_results).and_return([linted_file_path]))
      fakefs_dir = Struct.new(:fakefs_dir)
      allow(fakefs_dir).to(receive(:children).and_return([checksum]))
      allow(FakeFS::Dir).to(receive(:new).and_return(fakefs_dir))

      expect { cache.prune }.to(output(/Skipping deletion of new cache result #{checksum} in prune/).to_stdout)

      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
    end

    it "prunes outdated cache results" do
      fakefs_dir = Struct.new(:fakefs_dir)
      allow(fakefs_dir).to(receive(:children).and_return([checksum, "fake-checksum"]))
      allow(FakeFS::Dir).to(receive(:new).and_return(fakefs_dir))
      allow(cache).to(receive(:hits).and_return([linted_file_path]))

      File.open(File.join(cache_dir, "fake-checksum"), "wb") do |f|
        f.write(cache_file_content)
      end

      expect { cache.prune }.to(output(/Cleaning deleted cached file with checksum fake-checksum/).to_stdout)

      expect(File.exist?(
        File.join(
          cache_dir,
          "fake-checksum"
        )
      )).to(be(false))
    end
  end

  describe "#add_new_result" do
    it "adds new result to cache object new_results attribute" do
      cache.add_new_result(linted_file_path)

      expect(cache.send(:new_results)).to(include(linted_file_path))
    end
  end

  describe "#add_hit" do
    it "adds new cache hit to cache object hits attribute" do
      cache.add_hit(linted_file_path)

      expect(cache.send(:hits)).to(include(linted_file_path))
    end
  end
end
