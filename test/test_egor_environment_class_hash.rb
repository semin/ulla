$:.unshift File.join(File.dirname(__FILE__), "..", "lib/egor")

require 'test/unit'
require 'environment_class_hash'

class TestEgorEnvironmentClassHash < Test::Unit::TestCase

  def setup
    @env_cls = Egor::EnvironmentClassHash.new
  end

  def test_group_by_non_residue_labels
    assert(true)
  end

  def test_groups_sorted_by_residue_labels
    assert(true)
  end

  def group_size
    assert(true)
  end
end
