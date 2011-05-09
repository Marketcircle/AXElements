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
    skip 'You need multiple monitors for this test' if SCREENS.count < 2
    SCREENS.each do |screen|
      frame = screen.frame
      point = frame.origin.dup.carbonize!
      assert_equal (frame.size.height + frame.origin.y), point.y, screen.frame.inspect
    end
  end

  def test_middle_of_secondary_screen_is_still_middle_of_secondary_screen
    skip 'You need multiple monitors for this test' if SCREENS.count < 2
    SCREENS.each do |screen|
      frame = screen.frame
      point = frame.origin
      point.x = ( frame.size.width / 2 )  + point.x
      point.y = ( frame.size.height / 2 ) + point.y
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
    assert_equal CGPointZero, CGPoint.center(CGPointZero, CGSizeZero)
  end

  def center origin_x, origin_y, width, height
    CGPoint.center(CGPoint.new(origin_x,origin_y), CGSize.new(width,height))
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
