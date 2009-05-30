module Ulla
  class EnvironmentFeature

    attr_accessor :name, :symbols, :labels, :constrained, :silent

    def initialize(name, symbols, labels, constrained, silent)
      @name         = name
      @symbols      = symbols
      @labels       = labels
      @constrained  = constrained
      @silent       = silent
    end

    def to_s
      [name, symbols.join, labels.join, constrained, silent].join(";")
    end

    def constrained?
      constrained == "T"
    end

    def silent?
      silent == "T"
    end
  end
end
