$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "nmatrix_extensions"

class TestNmatrixExtensions < Test::Unit::TestCase

  def test_pretty_string(opts={})
    m = NMatrix.float(3,3).indgen
    result ="#        A      B      C\n" +
            "VAL   0.00   1.00   2.00\n" +
            "      3.00   4.00   5.00\n" +
            "      6.00   7.00   8.00"
    assert_equal(result, m.pretty_string(:col_header => %w[A B C], :row_header => %w[VAL]))
  end
end
