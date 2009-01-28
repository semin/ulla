$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'math_extensions'

class TestMathExtensions < Test::Unit::TestCase

  def test_log2
    assert_equal(1, Math::log2(2))
  end
end
