module Ulla
  class Environment

    attr_accessor :amino_acids,
      :number,
      :label,
      :freq_array,
      :prob_array,
      :logo_array,
      :smooth_prob_array

    def initialize(number, label, amino_acids = "ACDEFGHIKLMNPQRSTVWYJ".split(''))
      @number             = number
      @label              = label
      @amino_acids        = amino_acids
      @freq_array         = NArray.float(@amino_acids.size)
      @prob_array         = NArray.float(@amino_acids.size)
      @logo_array         = NArray.float(@amino_acids.size)
      @smooth_prob_array  = NArray.float(@amino_acids.size)
    end

    def increase_residue_count(a, inc = 1.0)
      @freq_array[@amino_acids.index(a)] += inc
    end

    def label_set
      if $direction == 0
        label.split("").each_with_index.map { |l, i| "#{i}#{l}" }.to_set
      else
        label.gsub('-', '').split("").each_with_index.map { |l, i| "#{i}#{l}" }.to_set
      end
    end

    def to_s
      "#{number}-#{label}"
    end
  end
end
