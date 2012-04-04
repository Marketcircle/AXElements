require 'test/helper'
require 'ax/element'

class TestAXElement < MiniTest::Unit::TestCase

  def element
    @element ||= AX::Element.new REF
  end

  def test_methods_is_flat
    methods = element.methods
    assert_equal methods.flatten.sort!, methods.sort!
  end

  def test_setting_through_method_missing
    got_callback = false
    element.define_singleton_method :set do |attr, value|
      if attr == 'my_little_pony' && value == :firefly
        got_callback = true
      end
    end
    assert element.my_little_pony = :firefly
  end

  def test_respond_to_works_with_dynamic_setters
    window = element.attribute(:main_window)
    assert_respond_to window, :position=
    assert_respond_to window, :size=
    refute_respond_to window, :grandad=
  end

  def test_to_point
    def center_test position, size, expected
      element.define_singleton_method :attribute do |attr|
        case attr
        when :position then CGPointMake(*position)
        when :size     then CGSizeMake(*size)
        else raise ArgumentError
        end
      end
      assert_equal CGPointMake(*expected), element.to_point
    end

    # the nil case
    center_test CGPointZero, CGSizeZero, CGPointZero
    # simple square with origin at zero
    center_test [0,0], [2,2], [1,1]
    # simple square in positive positive quadrant
    center_test [1,1], [6,6], [4,4]
    # rect in positive positive quadrant
    center_test [1,2], [6,10], [4,7]
    # rect in negative positive quadrant
    center_test [-123.0,25.0], [6.0,10.0], [-120,30]
    # rect starts in negative positive quadrant but is in positive positive
    center_test [-10.0,70.0], [20,42], [0,91]
  end

end


class TestSearchResultBlankness < MiniTest::Unit::TestCase

  def test_array_blank
    [
      NSArray.array,
      [true]
    ].each do |ary|
      assert_equal ary.empty?, ary.blank?
    end
  end

  def test_nil_blank
    assert_equal true, nil.blank?
  end

  def test_element_blank
    assert_equal false, AX::Element.new(REF).blank?
  end

end
