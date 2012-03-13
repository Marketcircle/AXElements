require 'minitest/ax_elements'

class TestMiniTestAssertions < MiniTest::Unit::TestCase

  def test_methods_are_loaded
    assert_respond_to self, :assert_has_child
    assert_respond_to self, :assert_has_descendent
    assert_respond_to self, :refute_has_child
    assert_respond_to self, :refute_has_descendent
  end

  def test_assert_has_children_returns_found_item
  end

  def test_assert_has_children_raises_in_failure_case
    e = assert_raises MiniTest::Assertion do
      assert_has_child 
    end

    # @todo also check message
  end

end
