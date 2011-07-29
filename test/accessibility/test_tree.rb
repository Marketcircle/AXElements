class TestAccessibilityTreeClass < TestAX

  APP = AX::Application.new REF

  def test_is_height_aware
    tree = Accessibility::Tree.new APP.attribute :main_window
    tree.each_with_height do |element, height|
      sleep 0.01 # sometimes this test is too intense for MacRuby
      msg = element.inspect
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

end
