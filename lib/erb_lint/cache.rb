# frozen_string_literal: true

module ERBLint
  class Cache
    CACHE_DIRECTORY = ".erb-lint-cache"

    def initialize(config, file_loader = nil)
      @config = config
      @file_loader = file_loader
      @hits = []
      @new_results = []
      puts "Cache mode is on"
    end

    def [](filename)
      JSON.parse(File.read(File.join(CACHE_DIRECTORY, checksum(filename)))).map do |offense|
        ERBLint::Offense.from_json(offense, @file_loader, config)
      end
    end

    def include?(filename)
      File.exist?(File.join(CACHE_DIRECTORY, checksum(filename)))
    end

    def []=(filename, offenses_as_json)
      FileUtils.mkdir_p(CACHE_DIRECTORY)

      File.open(File.join(CACHE_DIRECTORY, checksum(filename)), "wb") do |f|
        f.write(offenses_as_json)
      end
    end

    def add_hit(hit)
      @hits.push(hit)
    end

    def add_new_result(filename)
      @new_results.push(filename)
    end

    def prune
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
          puts "Skipping deletion of new cache result #{cache_file} in prune"
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
        "#{file}#{mode}#{config.to_hash}"
      )
      digester.file(file)
      digester.hexdigest
    rescue Errno::ENOENT
      # Spurious files that come and go should not cause a crash, at least not
      # here.
      "_"
    end
  end
end
