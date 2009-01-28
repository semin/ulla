$:.unshift File.join(File.dirname(__FILE__), "..", "lib/egor")

require "test/unit"
require "environment_feature"

class TestEnvironmentFeature < Test::Unit::TestCase

  def test_true
    assert(true)
  end
end
