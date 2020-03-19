module ERBLint
  class Stats
    attr_accessor :found, :corrected, :exceptions, :files
  
    def initialize
      @found = 0
      @corrected = 0
      @exceptions = 0
      @files = {}
    end
  end
end