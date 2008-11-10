$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "enumerable_extensions"

class TestEnumerableExtensions < Test::Unit::TestCase

  def test_cart_product
    a = [1,2]
    b = [3,4]
    products = [[1,3], [1,4], [2,3], [2,4]]
    results = Enumerable.cart_prod(a,b)
    assert_equal(4, results.size)
    products.each { |p| assert(results.include? p) }
  end
end
