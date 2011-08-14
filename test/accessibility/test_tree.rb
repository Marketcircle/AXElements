# -*- coding: utf-8 -*-
class TestAccessibilityTreeClass < TestAX

  APP = AX::Application.new REF

  def test_is_height_aware
    tree = Accessibility::Tree.new APP.attribute :main_window
    tree.each_with_height do |element, height|
      # msg = element.inspect # for debugging, otherwise makes test too intense for MacRuby
      case element.class.to_s
      when 'AX::CloseButton','AX::ZoomButton','AX::Slider','AX::RadioGroup','AX::ScrollArea','AX::CheckBox','AX::Incrementor','AX::SearchField'
        assert_equal 1, height
      when 'AX::WebArea','AX::Table','AX::ScrollBar'
        assert_equal 2, height
      when 'AX::SortButton'
        assert_equal 4, height
      end
    end
  end

  def test_is_breadth_first
    tree = Accessibility::Tree.new(APP.main_window.children.find { |x| x.class == AX::TabGroup })
    actual = tree.map &:class
    expected = [
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
    tree = Accessibility::Tree.new(APP)
    def tree.first
      each { |x| return x }
    end
    assert_equal AX::StandardWindow, tree.first.class
  end

  def test_find_returns_immediately_after_something_is_found
    tree = Accessibility::Tree.new(APP.main_window)
    cache = []
    tree.find do |element|
      cache << element.class
      element.class == AX::Slider
    end
    ['AX::ValueIndicator', 'AX::IncrementArrow'].each do |klass|
      refute_includes cache, klass.to_s
    end
  end

  def test_to_dot_generates_a_nice_dot_graph
    skip 'Not done yet'
  end

  def test_dump_includes_everyone_in_the_right_order_with_correct_indentation
    output = Accessibility::Tree(APP.main_window.children.find { |item| item.role == KAXTabGroupRole }).dump
    refute_empty dump

    expected = [
                ['AX::TabGroup',    0],
                ['AX::RadioButton', 1], ['AX::RadioButton', 1], ['AX::TabGroup', 1],
                ['AX::RadioButton', 2], ['AX::RadioButton', 2], ['AX::TabGroup', 2],
                ['AX::RadioButton', 3], ['AX::RadioButton', 3], ['AX::TabGroup', 3],
                ['AX::RadioButton', 4], ['AX::RadioButton', 4], ['AX::TabGroup', 4],
                ['AX::TextField',   5], ['AX::StaticText',  6],
                ['AX::TextField' ,  5], ['AX::StaticText',  6]
               ]

    output = output.split("\n")
    until output.empty?
      actual_line             = output.shift
      expected_klass, indents = expected.shift
      assert_equal indents, actual_line.match(/^\t+/).to_a.first.length

      actual_line.strip!
      assert_match /^\#<#{expected.shift}/, line
    end
  end

end
