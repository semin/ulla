module Ulla
  class Esst

    attr_accessor :type, :label, :no, :colnames, :rownames, :matrix

    def initialize(type, label, no, colnames=[], rownames=[], matrix = nil)
      @type     = type
      @label    = label
      @no       = no
      @colnames = colnames
      @rownames = rownames
      @matrix   = matrix
    end

    def scores_from(aa)
      i = colnames.index(aa)
      @matrix[i, 0..-1]
    end

    def scores_to(aa)
      j = rownames.index(aa)
      @matrix[0..-1, j]
    end

    def score(from_aa, to_aa)
      i = colnames.index(from_aa)
      j = rownames.index(to_aa)
      @matrix[i, j]
    end

  end
end
