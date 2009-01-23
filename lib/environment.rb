require "rubygems"
require "set"
require "narray"
require "facets"

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

if $0 == __FILE__

  require "test/unit"

  class TestEnvironment < Test::Unit::TestCase

    def setup
      @env = Environment.new(1, "AHaSon")
    end

    def test_label_set
      assert_equal(%w[0A 1H 2a 3S 4o 5n].to_set, @env.label_set)
    end

    def test_to_s
      assert_equal("1-AHaSon", @env.to_s)
    end

  end
end
