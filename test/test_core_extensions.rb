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

class TestNSMutableStringCamelizeBang < MiniTest::Unit::TestCase
  def test_takes_snake_case_string_and_makes_it_camel_case
    assert_equal 'AMethodName', 'a_method_name'.camelize!
    assert_equal 'MethodName',  'method_name'.camelize!
    assert_equal 'Name',        'name'.camelize!
  end
  def test_takes_camel_case_and_does_nothing
    assert_equal 'AMethodName', 'AMethodName'.camelize!
    assert_equal 'MethodName',  'MethodName'.camelize!
    assert_equal 'Name',        'Name'.camelize!
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

class TestCGPointExtensions < MiniTest::Unit::TestCase
  SCREENS     = NSScreen.screens
  MAIN_SCREEN = NSScreen.mainScreen
end

class TestCGPointCarbonizeBang < TestCGPointExtensions
  def test_nil_if_coordinates_not_on_any_screen
    frames    = SCREENS.map(&:frame)
    max_x     = frames.map(&:origin).map(&:x)    .max
    max_width = frames.map(&:size)  .map(&:width).max
    assert_nil CGPoint.new(max_x + max_width + 1, 0).carbonize!
  end
  def test_origin_in_cocoa_is_bottom_left_in_carbon
    point = CGPointZero.dup.carbonize!
    assert_equal MAIN_SCREEN.frame.size.height, point.y
  end
  def test_middle_of_screen_is_still_middle_of_screen
    frame = MAIN_SCREEN.frame
    point = frame.origin
    point.x = frame.size.width / 2
    point.y = frame.size.height / 2
    assert_equal point, point.dup.carbonize!
  end
  def test_origin_on_secondary_screen_is_bottom_left_of_secondary_screen
    skip 'You need multiple monitors for this test' if SCREENS.size < 2
    SCREENS.each do |screen|
      frame = screen.frame
      point = frame.origin.dup.carbonize!
      assert_equal (frame.size.height - frame.origin.y), point.y, screen.frame.inspect
    end
  end
  def test_middle_of_secondary_screen_is_still_middle_of_secondary_screen
    skip 'You need multiple monitors for this test' if SCREENS.size < 2
    SCREENS.each do |screen|
      frame = screen.frame
      point = frame.origin
      point.x = frame.size.width / 2
      point.y = frame.size.height / 2
      assert_equal point, point.dup.carbonize!
    end
  end
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
  def test_simple_square_starting_at_origin
    point = center_of_rect(0.0, 0.0, 2.0, 2.0)
    assert_equal 1.0, point.x
    assert_equal 1.0, point.y
  end
  def test_simple_square_not_at_origin
    point = center_of_rect(1.0, 1.0, 6.0, 6.0)
    assert_equal 3.5, point.x
    assert_equal 3.5, point.y
  end
  def test_rect_not_at_origin
    point = center_of_rect(1.0, 2.0, 6.0, 10.0)
    assert_equal 3.5, point.x
    assert_equal 6.0, point.y
  end
  def test_rect_with_negative_values
    point = center_of_rect(-1.0, -2.0, 6.0, 10.0)
    assert_equal 2.5, point.x
    assert_equal 4.0, point.y
  end
end

class TestCGPointCenter < TestCGPointExtensions
  def test_unaltered_with_cgrectzero
    assert_equal CGPointZero, CGPoint.center(CGPointZero, CGSizeZero)
  end

  def center origin_x, origin_y, width, height
    CGPoint.center(CGPoint.new(origin_x,origin_y), CGSize.new(width,height))
  end
  def test_simple_square_starting_at_origin
    point = center(0.0, 0.0, 2.0, 2.0)
    assert_equal 1.0, point.x
    assert_equal 1.0, point.y
  end
  def test_simple_square_not_at_origin
    point = center(1.0, 1.0, 6.0, 6.0)
    assert_equal 3.5, point.x
    assert_equal 3.5, point.y
  end
  def test_rect_not_at_origin
    point = center(1.0, 2.0, 6.0, 10.0)
    assert_equal 3.5, point.x
    assert_equal 6.0, point.y
  end
  def test_rect_with_negative_values
    point = center(-1.0, -2.0, 6.0, 10.0)
    assert_equal 2.5, point.x
    assert_equal 4.0, point.y
  end
end
