module Egor
  class Environment

    attr_accessor :amino_acids,
      :number,
      :label,
      :freq_array,
      :prob_array,
      :logo_array,
      :smooth_prob_array

    def initialize(number, label, amino_acids = "ACDEFGHIKLMNPQRSTVWYJ".split(''))
      @amino_acids        = amino_acids
      @number             = number
      @label              = label
      @freq_array         = $noweight ? NArray.int(@amino_acids.size) : NArray.float(@amino_acids.size)
      @prob_array         = NArray.float(@amino_acids.size)
      @logo_array         = NArray.float(@amino_acids.size)
      @smooth_prob_array  = NArray.float(@amino_acids.size)
    end

    def increase_residue_count(a, inc = 1.0)
      @freq_array[@amino_acids.index(a.upcase)] += inc
    end

    def label_set
      label.split("").map_with_index { |l, i| "#{i}#{l}" }.to_set
    end

    def to_s
      "#{number}-#{label}"
    end
  end
end
