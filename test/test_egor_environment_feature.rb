$:.unshift File.join(File.dirname(__FILE__), '..', 'lib', 'egor')

require 'test/unit'
require 'environment_feature'

class TestEgorEnvironmentFeature < Test::Unit::TestCase

  def setup
    @env_ftr = Egor::EnvironmentFeature.new('Secondary Structure',
                                            'HEPC'.split(''),
                                            'HEPC'.split(''),
                                            'T',
                                            'F')
  end

  def test_to_s
    assert_equal('Secondary Structure;HEPC;HEPC;T;F', @env_ftr.to_s)
  end

  def test_constrained?
    assert(@env_ftr.constrained?)
  end

  def silent?
    assert(!@env_ftr.silent?)
  end
end
