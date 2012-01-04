class TestNSArrayAccessors < MiniTest::Unit::TestCase

  def test_second_returns_second_from_array
    [[1,2],[:one,:two]].each { |array|
      assert_equal array.last, NSArray.arrayWithArray(array).second
      assert_equal array.last, array.second
    }
  end

  def test_second_returns_nil_from_array_of_one
    [[1], [:one]].each { |array|
      assert_nil NSArray.arrayWithArray(array).second
      assert_nil array.second
    }
  end

  def test_second_returns_second_from_array
    [[1,2,3],[:one,:two,:three]].each { |array|
      assert_equal array.last, NSArray.arrayWithArray(array).third
      assert_equal array.last, array.third
    }
  end

  def test_second_returns_nil_from_array_of_two
    [[1,2], [:one,:two]].each { |array|
      assert_nil NSArray.arrayWithArray(array).third
      assert_nil array.third
    }
  end

end


class TestNSArrayToPoint < MiniTest::Unit::TestCase

  def test_makes_a_point
    assert_instance_of CGPoint, [1, 1].to_point
  end

  def test_uses_first_two_elements
    assert_equal CGPoint.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_point
  end

end


class TestNSArrayToSize < MiniTest::Unit::TestCase

  def test_makes_a_point
    assert_instance_of CGSize, [1, 1].to_size
  end

  def test_uses_first_two_elements
    assert_equal CGSize.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_size
  end

end


class TestNSArrayToRect < MiniTest::Unit::TestCase

  def test_makes_a_rect
    assert_instance_of CGRect, [1, 1, 1, 1].to_rect
  end

  def test_uses_first_two_elements
    expected = CGRect.new(CGPoint.new(4,3),CGSize.new(2,5))
    actual   = NSArray.arrayWithArray([4, 3, 2, 5, 7]).to_rect
    assert_equal expected, actual
  end

end


class TestNSStringCamelize < MiniTest::Unit::TestCase

  def test_takes_snake_case_string_and_makes_it_camel_case
    assert_equal 'AMethodName', 'a_method_name'.camelize
    assert_equal 'MethodName',  'method_name'.camelize
    assert_equal 'Name',        'name'.camelize
  end

  def test_takes_camel_case_and_does_nothing
    assert_equal 'AMethodName', 'AMethodName'.camelize
    assert_equal 'MethodName',  'MethodName'.camelize
    assert_equal 'Name',        'Name'.camelize
  end

end


class TestNSStringUnderscore < MiniTest::Unit::TestCase

  # a better test might be to take the method and bind it into a
  # different context where ActiveSupport::Inflector resolved to
  # a mock class with a mocked version #underscore
  def test_calls_active_support
    assert_equal 'hello_this_is_dog', 'HelloThisIsDog'.underscore
    assert_equal 'nothing',           'nothing'.underscore
  end

end


class TestNSStringPredicate < MiniTest::Unit::TestCase

  def test_true_if_string_ends_with_a_question_mark
    assert 'test?'.predicate?
  end

  def test_false_if_the_string_does_not_end_with_a_question_mark
    refute 'tes?t'.predicate?
    refute 'te?st'.predicate?
    refute 't?est'.predicate?
    refute '?test'.predicate?
  end

  def test_false_if_the_string_has_no_question_mark
    refute 'test'.predicate?
  end

end


class TestNSStringSingularize < MiniTest::Unit::TestCase

  # a better test might be to take the method and bind it into a
  # different context where ActiveSupport::Inflector resolved to
  # a mock class with a mocked version #singularize
  def test_calls_active_support
    assert_equal 'octopus', NSString.alloc.initWithString('octopi').singularize
    assert_equal 'ox', NSString.alloc.initWithString('oxen').singularize
    assert_equal 'box', NSString.alloc.initWithString('boxes').singularize
    assert_equal 'box', NSString.alloc.initWithString('box').singularize
  end

end


class TestNSArrayMethodMissing < MiniTest::Unit::TestCase

  ELEMENTS = AX::DOCK.list.application_dock_items

  def test_delegates_up_if_array_is_not_composed_of_elements
    assert_raises NoMethodError do [1].title_ui_element end
  end

  def test_simple_attribute
    refute_empty ELEMENTS.url.compact
  end

  def test_artificially_plural_attribute
    refute_empty ELEMENTS.urls.compact
  end

  def test_naturally_plural_attribute
    refute_empty ELEMENTS.children.compact
  end

  def test_predicate_method
    refute_empty ELEMENTS.application_running?.compact
  end

end


class TestCGPointExtensions < MiniTest::Unit::TestCase
  SCREENS     = NSScreen.screens
  MAIN_SCREEN = NSScreen.mainScreen
end


class TestCGPointCenterOfRect < TestCGPointExtensions

  def test_unaltered_with_cgrectzero
    assert_equal CGPointZero, CGPoint.center_of_rect(CGRectZero)
  end

  def test_middle_of_screen
    frame = MAIN_SCREEN.frame
    point = frame.origin.dup
    point.x = frame.size.width / 2
    point.y = frame.size.height / 2
    assert_equal point, CGPoint.center_of_rect(frame)
  end

  def center_of_rect origin_x, origin_y, width, height
    rect = CGRect.new(CGPoint.new(origin_x,origin_y), CGSize.new(width,height))
    CGPoint.center_of_rect(rect)
  end

  def test_simple_square_with_origin_at_zero
    point = center_of_rect(0.0, 0.0, 2.0, 2.0)
    assert_equal 1, point.x
    assert_equal 1, point.y
  end

  def test_simple_square_in_positive_positive_quadrant
    point = center_of_rect(1.0, 1.0, 6.0, 6.0)
    assert_equal 4, point.x
    assert_equal 4, point.y
  end

  def test_rect_in_positive_positive_quadrant
    point = center_of_rect(1.0, 2.0, 6.0, 10.0)
    assert_equal 4, point.x
    assert_equal 7, point.y
  end

  def test_rect_in_negative_positive_quadrant
    point = center_of_rect(-123.0, 25.0, 6.0, 10.0)
    assert_equal -120, point.x
    assert_equal 30, point.y
  end

  def test_rect_starts_in_negative_positive_quadrant_but_is_in_positive_positive
    point = center_of_rect(-10.0, 70.0, 20.0, 42.0)
    assert_equal 0, point.x
    assert_equal 91, point.y
  end

end


class TestCGPointCenter < TestCGPointExtensions

  def test_unaltered_with_cgrectzero
    assert_equal CGPointZero, CGPointZero.center(CGSizeZero)
  end

  def center origin_x, origin_y, width, height
    CGPoint.new(origin_x,origin_y).center CGSize.new(width,height)
  end

  def test_simple_square_with_origin_at_zero
    point = center(0.0, 0.0, 2.0, 2.0)
    assert_equal 1, point.x
    assert_equal 1, point.y
  end

  def test_simple_square_in_positive_positive_quadrant
    point = center(1.0, 1.0, 6.0, 6.0)
    assert_equal 4, point.x
    assert_equal 4, point.y
  end

  def test_rect_in_positive_positive_quadrant
    point = center(1.0, 2.0, 6.0, 10.0)
    assert_equal 4, point.x
    assert_equal 7, point.y
  end

  def test_rect_in_negative_positive_quadrant
    point = center(-123.0, 25.0, 6.0, 10.0)
    assert_equal -120, point.x
    assert_equal 30, point.y
  end

  def test_rect_starts_in_negative_positive_quadrant_but_is_in_positive_positive
    point = center(-10.0, 70.0, 20.0, 42.0)
    assert_equal 0, point.x
    assert_equal 91, point.y
  end

end


class TestCGPointToPoint < MiniTest::Unit::TestCase

  def test_returns_self
    assert_equal CGPointZero, CGPointZero.to_point
    point = CGPoint.new(1, 1)
    assert_equal point, point.to_point
  end

end


class TestBoxedToAXValue < MiniTest::Unit::TestCase

  def test_point_makes_a_value
    value = CGPointZero.to_axvalue
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(value, 1, ptr)
    assert_equal CGPointZero, ptr[0]
  end

  def test_size_makes_a_value
    value = CGSizeZero.to_axvalue
    ptr   = Pointer.new CGSize.type
    AXValueGetValue(value, 2, ptr)
    assert_equal CGSizeZero, ptr[0]
  end

  def test_rect_makes_a_value
    value = CGRectZero.to_axvalue
    ptr   = Pointer.new CGRect.type
    AXValueGetValue(value, 3, ptr)
    assert_equal CGRectZero, ptr[0]
  end

  def test_range_makes_a_value
    range = CFRange.new(5, 4)
    value = range.to_axvalue
    ptr   = Pointer.new CFRange.type
    AXValueGetValue(value, 4, ptr)
    assert_equal range, ptr[0]
  end

  def test_values
    [[CGPoint, 1], [CGSize, 2], [CGRect, 3], [CFRange, 4]].each do |klass, value|
      assert_equal value, klass.instance_variable_get(:@ax_value)
    end
  end

end
