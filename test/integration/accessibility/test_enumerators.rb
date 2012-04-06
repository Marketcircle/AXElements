require 'test/integration/helper'

class TestAccessibilityEnumeratorsBreadthFirst < MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new REF
  end

  def test_each_iterates_in_correct_order
    tab_group = app.main_window.children.find { |x| x.class == AX::TabGroup }
    enum      = Accessibility::Enumerators::BreadthFirst.new(tab_group)
    actual    = enum.map &:class
    expected  = [
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::Group,
                 AX::TextField,   AX::TextField,
                 AX::StaticText,  AX::StaticText
                ]
    assert_equal expected, actual
  end

  def test_first_element_is_first_child # not the root
    enum = Accessibility::Enumerators::BreadthFirst.new app
    def enum.first
      each { |x| return x }
    end
    refute_instance_of AX::Application, enum.first
  end

  # this was a big performance issue, so we should make sure it
  # doesn't happen again
  def test_find_returns_immediately_after_finding
    tree  = Accessibility::Enumerators::BreadthFirst.new app
    cache = []
    tree.find do |element|
      cache << element.class
      element.class == AX::StandardWindow
    end
    assert_equal 1, cache.size
  end

  def bench_each
    skip 'TODO'
  end

  def bench_find
    skip 'TODO'
  end

end


class TestAccessibilityEnumeratorsDepthFirst < MiniTest::Unit::TestCase
  include Accessibility::Core

  def app
    @@app ||= AX::Application.new REF
  end

  def test_each_iterates_in_correct_order
    tab_group = app.main_window.children.find { |x| x.class == AX::TabGroup }
    enum      = Accessibility::Enumerators::DepthFirst.new tab_group
    actual    = enum.map &:class
    expected  = [
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::Group,
                 AX::TextField, AX::StaticText,
                 AX::TextField, AX::StaticText
                ]
    assert_equal expected, actual
  end

  # since we have a different implementation, we should also verify order here...
  def test_each_with_level_in_correct_order
    tab_group = app.main_window.children.find { |x| x.class == AX::TabGroup }
    enum      = Accessibility::Enumerators::DepthFirst.new tab_group
    actual    = []
    enum.each_with_level do |x,_| actual << x.class end
    expected  = [
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::TabGroup,
                 AX::RadioButton, AX::RadioButton, AX::Group,
                 AX::TextField, AX::StaticText,
                 AX::TextField, AX::StaticText
                ]
    assert_equal expected, actual
  end

  def test_each_with_level_has_correct_height
    enum   = Accessibility::Enumerators::DepthFirst.new app.main_window
    actual = []
    enum.each_with_level do |element, level|
      actual << [element.class, level]
    end

    assert_includes actual, [AX::Slider,         1]
    assert_includes actual, [AX::CloseButton,    1]
    assert_includes actual, [AX::ZoomButton,     1]
    assert_includes actual, [AX::MinimizeButton, 1]
    assert_includes actual, [AX::SearchField,    1]
    assert_includes actual, [AX::CheckBox,       1]
    assert_includes actual, [AX::WebArea,        2]
    assert_includes actual, [AX::Table,          2]
    assert_includes actual, [AX::ScrollBar,      2]
    assert_includes actual, [AX::SortButton,     4]
  end

  def bench_each
    skip 'TODO'
  end

  def bench_each_with_level
    skip 'TODO'
  end

end
