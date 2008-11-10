require "rubygems"
require "set"
require "narray"
require "facets"

class Environment

  @@amino_acids  = "ACDEFGHIKLMNPQRSTVWYJ".split("")

  attr_accessor :number,
                :label,
                :freq_array,
                :prob_array,
                :logodd_array,
                :smooth_prob_array

  def initialize(number, label)
    @number             = number
    @label              = label
    @freq_array         = $noweight ? NArray.int(21) : NArray.float(21)
    @prob_array         = NArray.float(21)
    @logodd_array       = NArray.float(21)
    @smooth_prob_array  = NArray.float(21)
  end

  def add_residue_count(a, inc = 1.0)
    @freq_array[@@amino_acids.index(a.upcase)] += inc
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