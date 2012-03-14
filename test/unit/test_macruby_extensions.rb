class TestNSDictionaryExtensions < MiniTest::Unit::TestCase

  def test_ax_pp
    assert_equal ::EMPTY_STRING,            {}.ax_pp
    assert_equal '(title: "Hey, listen!")', {title: 'Hey, listen!'}.ax_pp
    assert_equal '(a: 42, b: [3.14])',      {a: 42, b: [3.14]}.ax_pp
    assert_equal '(c(d: ":("))',            {c: {d:':('} }.ax_pp
  end

end


class TestNSArrayExtensions < MiniTest::Unit::TestCase

  def test_second_returns_second
    assert_equal :two, NSArray.arrayWithArray([:one, :two]).second
    assert_nil         NSArray.arrayWithArray([:one]).second
  end

  def test_third_returns_third
    assert_equal :three, NSArray.arrayWithArray([:one, :two, :three]).third
    assert_nil           NSArray.arrayWithArray([:one, :two]).third
  end

  def test_to_point
    assert_instance_of CGPoint, [1, 1].to_point
    assert_equal CGPoint.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_point
  end

  def test_to_size
    assert_instance_of CGSize, [1, 1].to_size
    assert_equal CGSize.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_size
  end

  def test_to_rect
    assert_instance_of CGRect, [1, 1, 1, 1].to_rect

    expected = CGRect.new(CGPoint.new(4,3),CGSize.new(2,5))
    actual   = NSArray.arrayWithArray([4, 3, 2, 5, 7]).to_rect
    assert_equal expected, actual
  end

  def test_blank
    ary = NSArray.array
    assert_equal ary.method(:empty?), ary.method(:blank?)
  end

  def test_method_missing
    assert_raises NoMethodError do
      [1].rows
    end
    assert_raises NoMethodError do
      [REF].rows
    end
    assert_raises NoMethodError do
      [AX::DOCK, :cake].title
    end

    assert_equal ['Dock'], [AX::DOCK].titles
    assert_equal [false],  [AX::DOCK].focused?
    # @todo test getting rows from a table
  end
end


class TestNSStringExtensions < MiniTest::Unit::TestCase

  def test_empty_string_constant
    assert Object.const_get(:EMPTY_STRING)
  end

  def test_predicate?
    assert 'test?'.predicate?

    refute 'tes?t'.predicate?
    refute 'te?st'.predicate?
    refute 't?est'.predicate?
    refute '?test'.predicate?

    refute 'test'.predicate?
  end

  def test_singularize_calls_active_support
    assert_equal 'octopus', NSString.alloc.initWithString('octopi').singularize
    assert_equal 'ox',      NSString.alloc.initWithString('oxen').singularize
    assert_equal 'box',     NSString.alloc.initWithString('boxes').singularize
    assert_equal 'box',     NSString.alloc.initWithString('box').singularize
  end

  def test_underscore_calls_active_support
    assert_equal 'hello_this_is_dog', 'HelloThisIsDog'.underscore
    assert_equal 'nothing',           'nothing'.underscore
  end

  def test_classify_calls_active_support
    assert_equal 'Alpha',        'alpha'.classify
    assert_equal 'BetaGamma',    'beta_gamma'.classify
    assert_equal 'DeltaEpsilon', 'delta_epsilons'.classify
  end

  def test_camelize
    assert_equal 'AMethodName', 'a_method_name'.camelize
    assert_equal 'MethodName',  'method_name'.camelize
    assert_equal 'Name',        'name'.camelize

    assert_equal 'AMethodName', 'AMethodName'.camelize
    assert_equal 'MethodName',  'MethodName'.camelize
    assert_equal 'Name',        'Name'.camelize
  end

  def test_blank?
    assert ''.blank?
    refute "\b".blank?
    refute 'bob'.blank?
    refute "\n".blank?
  end

end


class TestNSObjectExtensions < MiniTest::Unit::TestCase

  def test_to_axvalue_alias
    obj = Object.new
    assert_respond_to obj, :to_axvalue
    assert_equal obj.method(:self), obj.method(:to_axvalue)
  end

  def test_inspecting
    url = NSURL.URLWithString('http://marketcircle.com/')
    assert_equal url.description, url.inspect

    bundle = CFBundleGetMainBundle()
    assert_equal bundle.description, bundle.inspect
  end

end


class TestBoxedExtensions < MiniTest::Unit::TestCase
  include Accessibility::Core

  def test_to_axvalue_calls_back
    point = CGPointMake(1, 2)
    assert_equal wrap(point), point.to_axvalue

    size  = CGSizeMake(2, 5)
    assert_equal wrap(size), size.to_axvalue

    rect  = CGRectMake(5, 9, 8, 4)
    assert_equal wrap(rect), rect.to_axvalue

    range = CFRange.new(5, 4)
    assert_equal wrap(range), range.to_axvalue
  end

end


class TestCGPointExtensions < MiniTest::Unit::TestCase

  SCREENS     = NSScreen.screens
  MAIN_SCREEN = NSScreen.mainScreen

  def test_center
    def center origin_x, origin_y, width, height
      CGPoint.new(origin_x,origin_y).center CGSize.new(width,height)
    end

    assert_equal CGPointZero, CGPointZero.center(CGSizeZero)

    # simple square with origin at zero
    point = center(0.0, 0.0, 2.0, 2.0)
    assert_equal 1, point.x
    assert_equal 1, point.y

    # simple square in positive positive quadrant
    point = center(1.0, 1.0, 6.0, 6.0)
    assert_equal 4, point.x
    assert_equal 4, point.y

    # rect in positive positive quadrant
    point = center(1.0, 2.0, 6.0, 10.0)
    assert_equal 4, point.x
    assert_equal 7, point.y

    # rect in negative positive quadrant
    point = center(-123.0, 25.0, 6.0, 10.0)
    assert_equal -120, point.x
    assert_equal 30, point.y

    # rect starts in negative positive quadrant but is in positive positive
    point = center(-10.0, 70.0, 20.0, 42.0)
    assert_equal 0, point.x
    assert_equal 91, point.y
  end

  def test_to_point_returns_self
    assert_equal CGPointZero, CGPointZero.to_point
    point = CGPoint.new(1, 1)
    assert_equal point, point.to_point
  end

  def test_flipping
    size = NSScreen.mainScreen.frame.size
    assert_equal CGPointMake(  0, size.height    ), CGPointZero.dup.flip!
    assert_equal CGPointMake(100, size.height-200), CGPointMake(100,200).flip!
  end

  def test_flipping_twice_returns_to_original
    assert_equal CGPointZero.dup, CGPointZero.dup.flip!.flip!
  end

end


class TestCGRectExtensions < MiniTest::Unit::TestCase

  def test_flipping
    size = NSScreen.mainScreen.frame.size
    assert_equal CGRectMake(  0,     size.height,  0,  0), CGRectZero.dup.flip!
    assert_equal CGRectMake(100, size.height-200,100,100), CGRectMake(100,100,100,100).flip!
  end

  def test_flipping_twice_returns_to_original
    assert_equal CGRectZero.dup, CGRectZero.dup.flip!.flip!
  end

end


class TestNilClassExtensions < MiniTest::Unit::TestCase

  def test_blank
    assert_equal true, nil.blank?
  end

end
