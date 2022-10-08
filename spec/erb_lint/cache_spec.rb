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
  let(:checksum) { "2dc3e17183b87889cc783b0157723570d4bbb90a" }
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

    digest_sha1_double = instance_double(Digest::SHA1)
    allow(Digest::SHA1).to(receive(:new).and_return(digest_sha1_double))
    allow(digest_sha1_double).to(receive(:hexdigest).and_return(checksum))
    allow(digest_sha1_double).to(receive(:update).and_return(true))
    allow(digest_sha1_double).to(receive(:file).and_return(true))
  end

  describe "#get" do
    it "returns a cached lint result" do
      cache_result = cache.get(linted_file_path, linted_file_content)
      expect(cache_result.count).to(eq(2))
    end
  end

  describe "#[]=" do
    it "caches a lint result" do
      cache.set(linted_file_path, linted_file_content, cache_file_content)
      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
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

  describe "#prune_cache" do
    it "skips prune if no cache hits" do
      allow(cache).to(receive(:hits).and_return([]))

      expect { cache.prune_cache }.to(output(/Cache being created for the first time, skipping prune/).to_stdout)
    end

    it "does not prune actual cache hits" do
      cache.prune_cache

      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
    end

    it "does not prune new cache results" do
      allow(cache).to(receive(:hits).and_return(["fake-hit"]))
      allow(cache).to(receive(:new_results).and_return([checksum]))
      fakefs_dir = Struct.new(:fakefs_dir)
      allow(fakefs_dir).to(receive(:children).and_return([checksum]))
      allow(FakeFS::Dir).to(receive(:new).and_return(fakefs_dir))

      expect { cache.prune_cache }.to(output(/.*Skipping deletion of new cache result #{checksum}/).to_stdout)

      expect(File.exist?(
        File.join(
          cache_dir,
          checksum
        )
      )).to(be(true))
    end

    it "prunes unused cache results" do
      fakefs_dir = Struct.new(:fakefs_dir)
      allow(fakefs_dir).to(receive(:children).and_return([checksum, "fake-checksum"]))
      allow(FakeFS::Dir).to(receive(:new).and_return(fakefs_dir))
      allow(cache).to(receive(:hits).and_return([linted_file_path]))

      File.open(File.join(cache_dir, "fake-checksum"), "wb") do |f|
        f.write(cache_file_content)
      end

      expect { cache.prune_cache }.to(output(/Cleaning deleted cached file with checksum fake-checksum/).to_stdout)

      expect(File.exist?(
        File.join(
          cache_dir,
          "fake-checksum"
        )
      )).to(be(false))
    end
  end

  describe "prune cache mode on #get and #[] behavior" do
    before do
      allow(cache).to(receive(:prune?).and_return(true))
    end

    it "adds new result to cache object new_results list attribute" do
      cache.set(linted_file_path, linted_file_content, cache_file_content)

      expect(cache.send(:new_results)).to(include(checksum))
    end

    it "adds new cache hit to cache object hits list attribute" do
      cache.get(linted_file_path, linted_file_content)

      expect(cache.send(:hits)).to(include(checksum))
    end
  end

  describe "#close" do
    it "Calls prune_cache if prune_cache mode is on" do
      allow(cache).to(receive(:prune?).and_return(true))
      expect(cache).to(receive(:prune_cache))
      cache.close
    end
  end
end
