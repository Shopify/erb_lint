# frozen_string_literal: true

module ERBLint
  class Cache
    CACHE_DIRECTORY = ".erb-lint-cache"
    private_constant :CACHE_DIRECTORY

    def initialize(config)
      @config = config.to_hash
      @hits = []
      @new_results = []
    end

    def [](filename)
      JSON.parse(File.read(File.join(CACHE_DIRECTORY, checksum(filename))))
    end

    def include?(filename)
      File.exist?(File.join(CACHE_DIRECTORY, checksum(filename)))
    end

    def []=(filename, messages)
      FileUtils.mkdir_p(CACHE_DIRECTORY)

      File.open(File.join(CACHE_DIRECTORY, checksum(filename)), "wb") do |f|
        f.write(messages.to_json)
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

        puts "Cleaning deleted cached file with checksum #{cache_file}}"
        File.delete(File.join(CACHE_DIRECTORY, cache_file))
      end

      @hits = []
    end

    def clear
      puts "Clearing cache by deleting cache directory..."
      begin
        FileUtils.remove_dir(CACHE_DIRECTORY)
        puts "...cache directory cleared"
      rescue Errno::ENOENT
        puts "...directory already doesn't exist, skipped deletion."
      end
    end

    private

    attr_reader :config, :hits, :new_results

    def checksum(file)
      digester = Digest::SHA1.new
      mode = File.stat(file).mode

      digester.update(
        "#{file}#{mode}#{config}"
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
