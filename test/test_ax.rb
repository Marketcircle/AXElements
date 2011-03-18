require 'helper'
require 'active_support/core_ext/array/access'

class TestAXAttributePrefix < MiniTest::Unit::TestCase
  def test_returns_regex
    assert_instance_of Regexp, AX.attribute_prefix
  end

  def test_is_overrideable
    assert AX.respond_to?(:attribute_prefix=)
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

  # @todo need to manipulate the mouse
  def test_returns_a_menubar_when_mouse_is_on_menubar
    skip 'This test is too invasive, need to find another way or add a test option'
  end
end

# @todo I should really have some more tests for this class
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
    assert_kind_of AX::Element, RET.first
  end

  def test_correctness
    assert_equal 3, RET.size
    assert_instance_of AX::ApplicationDockItem, RET.first
    assert_instance_of AX::List,                RET.second
    assert_instance_of AX::Application,         RET.third
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
