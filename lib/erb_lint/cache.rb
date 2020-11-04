# frozen_string_literal: true

module ERBLint
  class Cache
    CACHE_DIRECTORY = '.erb-lint-cache'
    private_constant :CACHE_DIRECTORY

    def initialize(config)
      @config = config.to_hash
    end

    def [](filename)
      JSON.parse(File.read(File.join(CACHE_DIRECTORY, checksum(filename))))
    end
    
    def include?(filename)
      File.exist?(File.join(CACHE_DIRECTORY, checksum(filename)))
    end
    
    def []=(filename, messages)
      FileUtils.mkdir_p(CACHE_DIRECTORY)

      File.open(File.join(CACHE_DIRECTORY, checksum(filename)), 'wb') do |f|
        f.write messages.to_json
      end
    end

    private

    attr_reader :config

    def checksum(file)
      digester = Digest::SHA1.new
      mode = File.stat(file).mode

      digester.update(
        "#{file}#{mode}#{config.to_s}"
      )
      digester.file(file)
      digester.hexdigest
    rescue Errno::ENOENT
      # Spurious files that come and go should not cause a crash, at least not
      # here.
      '_'
    end
  end
end
