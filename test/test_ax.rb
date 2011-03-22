class TestAXAccessibilityPrefix < MiniTest::Unit::TestCase
  def test_removes_ax_prefix
    ret = 'AXButton'.sub(AX.accessibility_prefix) { $1 }
    assert_equal 'Button', ret
  end
  def test_removes_other_prefxexs
    ret = 'MCButton'.sub(AX.accessibility_prefix) { $1 }
    assert_equal 'Button', ret
  end
  def test_removes_combination_prefixes
    ret = 'AXMCButton'.sub(AX.accessibility_prefix) { $1 }
    assert_equal 'Button', ret
  end
end

class TestAXNewConstGet < MiniTest::Unit::TestCase
  def test_returns_class_even_when_class_does_not_exist_yet
    assert_equal AX::Element, AX.new_const_get( :Element )
    assert_equal 'AX::RazzleDazzle', AX.new_const_get( :RazzleDazzle ).to_s
  end
  def test_creates_classes_if_they_do_not_exist
    refute AX.constants.include?( :MadeUpName )
    AX.new_const_get( :MadeUpName )
    assert AX.constants.include?( :MadeUpName )
    assert_instance_of Class, AX::MadeUpName
  end
end

class TestAXPluralConstGet < MiniTest::Unit::TestCase
  def test_finds_things_that_are_not_pluralized
    refute_nil AX.plural_const_get( 'Application' )
  end
  def test_finds_things_that_are_pluralized_with_an_s
    refute_nil AX.plural_const_get( 'Applications' )
  end
  def test_returns_nil_if_the_class_does_not_exist
    assert_nil AX.plural_const_get( 'NonExistant' )
  end
end

class TestAXCreateAXClass < MiniTest::Unit::TestCase
  def test_returns_constant
    assert_equal 'AX::HeyHeyHey', AX.create_ax_class( :HeyHeyHey ).to_s
  end
  def test_creates_classes_in_the_ax_namespace
    AX.create_ax_class( :AnotherTestClass )
    assert AX.constants.include?( :AnotherTestClass )
  end
  def test_makes_new_classes_a_subclass_of_ax_element
    AX.create_ax_class( :RoflCopter )
    assert AX::RoflCopter.ancestors.include?(AX::Element)
  end
end

class TestAXElementUnderMouse < MiniTest::Unit::TestCase
  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, AX.element_under_mouse
  end
  # @todo need to manipulate the mouse and put it in some
  #       well known locations and make sure I get the right
  #       element created
end

class TestAXElementAtPosition < MiniTest::Unit::TestCase
  def test_returns_a_menubar_for_coordinates_10_0
    item = AX.element_at_position( CGPoint.new(10, 0) )
    assert_instance_of AX::MenuBarItem, item
  end
end

class TestAXHierarchy < MiniTest::Unit::TestCase
  ITEM = AX::DOCK.list.application_dock_item
  RET  = AX.hierarchy( ITEM )
  def test_returns_array_of_elements
    assert_instance_of Array, RET
    assert_kind_of     AX::Element, RET.first
  end
  def test_correctness
    assert_equal 3, RET.size
    assert_instance_of AX::ApplicationDockItem, RET.first
    assert_instance_of AX::List,                RET.second
    assert_instance_of AX::Application,         RET.third
  end
end

class TestAXAttrsOfElement < MiniTest::Unit::TestCase
  def setup; @attrs = AX.attrs_of_element(AX::DOCK.ref); end
  def test_returns_array_of_strings
    assert_instance_of String, @attrs.first
  end
  def test_make_sure_certain_attributes_are_present
    assert @attrs.include?(KAXRoleAttribute)
    assert @attrs.include?(KAXChildrenAttribute)
    assert @attrs.include?(KAXTitleAttribute)
  end
end

class TestAXActionsOfElement < MiniTest::Unit::TestCase
  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element(AX::DOCK.ref)
  end
  def test_returns_array_of_strings
    actions = AX.actions_of_element(AX::DOCK.application_dock_item.ref)
    assert_instance_of String, actions.first
  end
  def test_make_sure_certain_actions_are_present
    actions = AX.actions_of_element(AX::DOCK.application_dock_item.ref)
    assert actions.include?(KAXPressAction)
    assert actions.include?(KAXShowMenuAction)
  end
end

class TestAXSYSTEM < MiniTest::Unit::TestCase
  def test_is_the_system_wide_object
    assert_instance_of AX::SystemWide, AX::SYSTEM
  end
end

class TestAXDOCK < MiniTest::Unit::TestCase
  def test_dock_is_an_application
    assert_instance_of AX::Application, AX::DOCK
  end
  def test_is_the_dock_application
    assert_equal 'Dock', AX::DOCK.title
  end
end

class TestAXFinder < MiniTest::Unit::TestCase
  def test_finder_is_an_application
    assert_instance_of AX::Application, AX::FINDER
  end
  def test_is_the_finder_application
    assert_equal 'Finder', AX::FINDER.title
  end
end
