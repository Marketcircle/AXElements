# -*- coding: utf-8 -*-

class TestAccessibilityBFEnumerator < TestAX

  APP = AX::Application.new REF

  def test_each_iterates_in_correct_order
    tab_group = APP.main_window.children.find { |x| x.class == AX::TabGroup }
    enum      = Accessibility::BFEnumerator.new(tab_group)
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
    enum = Accessibility::BFEnumerator.new(APP)
    def enum.first
      each { |x| return x }
    end
    assert_instance_of AX::StandardWindow, enum.first
  end

  # this was a "bug", so we should make sure it doesn't come back
  def test_find_returns_immediately_after_finding
    tree  = Accessibility::BFEnumerator.new(APP.attribute(:main_window))
    cache = []
    tree.find do |element|
      cache << element.class.to_s
      element.class == AX::Slider
    end
    refute_includes cache, 'AX::ValueIndicator'
    refute_includes cache, 'AX::IncrementArrow'
    assert_includes cache, 'AX::Slider'
  end

end


class TestAccessibilityDFEnumerator < TestAX

  APP = AX::Application.new REF

  def test_each_iterates_in_correct_order
    tab_group = APP.main_window.children.find { |x| x.class == AX::TabGroup }
    enum      = Accessibility::DFEnumerator.new tab_group
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
  def test_each_with_height_has_correct_height
    enum = Accessibility::DFEnumerator.new APP.attribute(:main_window)
    enum.each_with_height do |element, height|
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

end
