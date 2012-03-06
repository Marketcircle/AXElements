# arguably not unit tests, they depend on Core working
class TestAccessibilityFactory < MiniTest::Unit::TestCase
  include Accessibility::Factory

  def window
    children_for(REF).find { |x| role_for(x) == KAXWindowRole }
  end

  def scroll_area
    children_for(window).find { |x|
      attrs_for(x).include?(KAXDescriptionAttribute) &&
        value_of(KAXDescriptionAttribute, for: x) == 'Test Web Area'
    }
  end

  def web_area
    children_for(scroll_area).find { |x| role_for(x) == 'AXWebArea' }
  end

  def close_button
    children_for(window).find { |x|
      attrs_for(x).include?(KAXSubroleAttribute) &&
        value_of(KAXSubroleAttribute, for: x) == KAXCloseButtonSubrole
    }
  end

  def test_processing_element_refs
    assert_equal REF, process(REF).ref

    web_view = process web_area
    assert_instance_of AX::WebArea, web_view

    main_window = process window
    assert_instance_of AX::StandardWindow, main_window
    button = process close_button
    assert_instance_of AX::CloseButton, button

    # intentionally done a second time to see if the
    # created class is used again; this guarantees
    # that the class can be created properly and then
    # used again when needed
    main_window = process window
    assert_instance_of AX::StandardWindow, main_window
    button = process close_button
    assert_instance_of AX::CloseButton, button

    application = process REF
    assert_instance_of AX::Application, application
    scroll_view = process scroll_area
    assert_instance_of AX::ScrollArea, scroll_view

    # again, we do it a second time
    application = process REF
    assert_instance_of AX::Application, application
    scroll_view = process scroll_area
    assert_instance_of AX::ScrollArea, scroll_view
  end

  def test_processing_arrays
    assert_equal [],    process_array([])
    assert_equal [1],   process_array([1])

    expected = [AX::Application.new(REF)]
    assert_equal expected, process_array([REF])
  end

  def test_processing_boxes
    point = CGPointMake(rand(1000),rand(1000))
    assert_equal point, process(point.to_axvalue)

    size = CGSizeMake(rand(1000),rand(1000))
    assert_equal size, process(size.to_axvalue)

    rect = CGRectMake(*point.to_a,*size.to_a)
    assert_equal rect, process(rect.to_axvalue)

    range = CFRange.new(rand(100),rand(1000))
    assert_equal range, process(range.to_axvalue)
  end

  def test_processing_arbitrary_objects
    assert_equal 'test', process('test')
    assert_equal 42,     process(42)

    now = Time.now
    assert_equal now, process(now)

    string = NSAttributedString.alloc.initWithString 'hi'
    assert_equal string, process(string)
  end

  def test_processing_nil
    assert_nil process(nil)
  end

  def bench_process
    skip 'This is important when we get to optimizing'
  end

end
