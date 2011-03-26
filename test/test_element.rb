class TestAXElementAttributes < MiniTest::Unit::TestCase
  def test_not_empty
    refute_empty AX::DOCK.attributes
  end
  def test_contains_proper_info
    assert AX::DOCK.attributes.include?(KAXRoleAttribute)
    assert AX::DOCK.attributes.include?(KAXTitleAttribute)
  end
end

class TestAXElementActions < MiniTest::Unit::TestCase
  def setup
    super
    list = AX.raw_attr_of_element(DOCK,KAXChildrenAttribute).first
    app = AX.raw_attr_of_element(list,KAXChildrenAttribute).first
    @el = AX::Element.new(app)
  end
  def test_not_empty
    refute_empty @el.actions
  end
  def test_contains_proper_info
    assert @el.actions.include?(KAXPressAction)
    assert @el.actions.include?(KAXShowMenuAction)
  end
end

class TestAXElementPID < MiniTest::Unit::TestCase
  def test_actually_works
    assert_instance_of Fixnum, AX::DOCK.pid
    refute AX::DOCK.pid == 0
  end
end

class TestAXElementAttributeWritable < MiniTest::Unit::TestCase
  def test_raises_error_for_non_existant_attributes
    assert_raises ArgumentError do
      AX::DOCK.attribute_writable?(:fake_attribute)
    end
  end
  def test_true_for_writable_attributes
    list = AX.raw_attr_of_element(DOCK,KAXChildrenAttribute).first
    app  = AX.raw_attr_of_element(list,KAXChildrenAttribute).first
    @el  = AX::Element.new(app)
    assert @el.attribute_writable?(KAXSelectedAttribute)
  end
  def test_false_for_non_writable_attributes
    refute AX::DOCK.attribute_writable?(KAXTitleAttribute)
  end
end

class TestAXElementGetAttribute < MiniTest::Unit::TestCase
  def test_returns_nil_for_non_existent_attributes
    assert_nil AX::DOCK.get_attribute 'fakeattribute'
  end
  def test_fetches_attribute
    assert_equal 'Dock', AX::DOCK.get_attribute(KAXTitleAttribute)
  end
end

# @todo this is a bit too invasive right now
# class TestAXElementGetParamAttribute < MiniTest::Unit::TestCase
#   def test_returns_nil_for_non_existent_attributes
#   end
#   def test_fetches_attribute
#   end
# end

# @todo this is a bit too invasive right now
# class TestAXElementSetAttribute < MiniTest::Unit::TestCase
# end

# @todo this is a bit too invasive right now
# class TestAXElementSetFocus < MiniTest::Unit::TestCase
# end

# @todo this is a bit too invasive right now
# class TestAXElementPerformAction < MiniTest::Unit::TestCase
# end

class TestAXElementMethodMissing < MiniTest::Unit::TestCase
  # def test_finds_setters
  # end
  def test_finds_attribute
    assert_equal 'Dock', AX::DOCK.title
  end
  # def test_finds_actions
  # end
  # def test_does_search_if_has_kids
  # end
  # def test_does_not_search_if_no_kids
  # end
end

class TestAXElementRaise < MiniTest::Unit::TestCase
  # def test_delegates_up_if_raise_not_an_action
  # end
  # def test_calls_raise_if_raise_is_an_action
  # end
end

class TestAXElementDescription < MiniTest::Unit::TestCase
end

class TestAXElementPrettyPrint < MiniTest::Unit::TestCase
end

class TestAXElementInspect < MiniTest::Unit::TestCase
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
    assert AX::DOCK.respond_to?(:attributes)
  end
  def test_returns_false_for_non_existant_methods
    refute AX::DOCK.respond_to?(:crazy_thing_that_cant_work)
  end
end

class TestAXElementMethods < MiniTest::Unit::TestCase
end
