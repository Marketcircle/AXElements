class TestAXElement < MiniTest::Unit::TestCase
  def test_can_click
    assert AX::Element.instance_methods.include?(:left_click)
  end

  def test_can_wait_for_notifications
    assert AX::Element.instance_methods.include?(:wait_for_notification)
  end
end

class TestAXElementMethodMissing < MiniTest::Unit::TestCase
  def test_finds_attributes
    assert_equal 'Dock', AX::DOCK.title
  end

  def test_finds_actions
    skip 'This test is too invasive, need to find another way or add a test option'
  end
end

class TestAXElementAttributeWritable < MiniTest::Unit::TestCase
  def test_raises_error_for_non_existant_error
    assert_raises ArgumentError do
      AX::DOCK.attribute_writable?(:fake_attribute)
    end
  end

  def test_true_for_writable_attributes
    assert AX::DOCK.application_dock_item.attribute_writable?(:selected?)
  end

  def test_false_for_non_writable_attributes
    refute AX::DOCK.attribute_writable?(:title)
  end

  def test_works_with_exact_attribute_name
    assert AX::DOCK.application_dock_item.attribute_writable?(KAXSelectedAttribute)
  end
end

class TestAXElementRespondTo < MiniTest::Unit::TestCase
  def test_works_on_attributes
    assert AX::DOCK.respond_to?(:title)
  end

  def test_works_on_actions
    assert AX::DOCK.list.application_dock_item.respond_to?(:press)
  end

  def test_does_not_work_with_search_names
    refute AX::DOCK.respond_to?(:list)
  end

  def test_works_for_regular_methods
    assert AX::DOCK.respond_to?(:ref)
  end

  def test_returns_false_for_non_existant_methods
    refute AX::DOCK.respond_to?(:crazy_thing_that_cant_work)
  end
end

# @todo test #search
# is breadth first
# plural works
# singular works
# assert performance of singular search
