require 'minitest/ax_elements'

class TestMiniTestAssertions < MiniTest::Unit::TestCase

  def test_methods_are_loaded
    assert_respond_to self, :assert_has_child
    assert_respond_to self, :assert_has_descendent
    assert_respond_to self, :assert_has_descendant
    assert_respond_to self, :refute_has_child
    assert_respond_to self, :refute_has_descendent
    assert_respond_to self, :refute_has_descendant
  end

end
