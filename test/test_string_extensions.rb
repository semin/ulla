$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "string_extensions"

class TestStringExtensions < Test::Unit::TestCase

  def test_remove_internal_spaces
    assert_equal("hellosemin", "he ll o\r\n sem in\r \n".remove_internal_spaces)
  end
end
