# frozen_string_literal: true

module ERBLint
  class Cache
    CACHE_DIRECTORY = ".erb-lint-cache"

    def initialize(config, file_loader = nil, prune = false)
      @config = config
      @file_loader = file_loader
      @hits = []
      @new_results = []
      @prune = prune
      puts "Cache mode is on"
    end

    def get(filename, file_content)
      @hits.push(filename) if prune?

      JSON.parse(File.read(File.join(CACHE_DIRECTORY, checksum(filename)))).map do |offense|
        ERBLint::Offense.from_json(offense, config, @file_loader, file_content)
      end
    end

    def include?(filename)
      File.exist?(File.join(CACHE_DIRECTORY, checksum(filename)))
    end

    def []=(filename, offenses_as_json)
      @new_results.push(filename) if prune?

      FileUtils.mkdir_p(CACHE_DIRECTORY)

      File.open(File.join(CACHE_DIRECTORY, checksum(filename)), "wb") do |f|
        f.write(offenses_as_json)
      end
    end

    def close
      prune_cache if prune?
    end

    def prune_cache
      puts "Prune cache mode is on - pruned file names will be logged"
      if hits.empty?
        puts "Cache being created for the first time, skipping prune"
        return
      end

      cache_files = Dir.new(CACHE_DIRECTORY).children
      hits_as_checksums = hits.map { |hit| checksum(hit) }
      new_results_as_checksums = new_results.map { |new_result| checksum(new_result) }
      cache_files.each do |cache_file|
        next if hits_as_checksums.include?(cache_file)

        if new_results_as_checksums.include?(cache_file)
          puts "Skipping deletion of new cache result #{cache_file}"
          next
        end

        puts "Cleaning deleted cached file with checksum #{cache_file}"
        File.delete(File.join(CACHE_DIRECTORY, cache_file))
      end

      @hits = []
    end

    def cache_dir_exists?
      File.directory?(CACHE_DIRECTORY)
    end

    def clear
      return unless cache_dir_exists?

      puts "Clearing cache by deleting cache directory"
      FileUtils.rm_r(CACHE_DIRECTORY)
    end

    private

    attr_reader :config, :hits, :new_results

    def checksum(file)
      digester = Digest::SHA1.new
      mode = File.stat(file).mode

      digester.update(
        "#{file}#{mode}#{config.to_hash}#{ERBLint::VERSION}"
      )
      digester.file(file)
      digester.hexdigest
    rescue Errno::ENOENT
      # Spurious files that come and go should not cause a crash, at least not
      # here.
      "_"
    end

    def prune?
      @prune
    end
  end
end
