$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "narray_extensions"

class TestArrayExtensions < Test::Unit::TestCase

  def test_pretty_string(opts={})
    m = NArray.float(3).indgen
    result ="#        A      B      C\n" +
            "VAL   0.00   1.00   2.00"
    assert_equal(result, m.pretty_string(:col_header => %w[A B C], :row_header => 'VAL'))
  end
end
