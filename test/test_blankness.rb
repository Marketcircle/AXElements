class TestBlankPredicate < MiniTest::Unit::TestCase

  def test_nil_returns_true
    assert_equal true, nil.blank?
  end

  def test_nsarray_responds
    assert_respond_to NSArray.array, :blank?
  end

  def test_nsarray_uses_alias_to_empty?
    ary = NSArray.array
    assert_equal ary.method(:empty?), ary.method(:blank?)
  end

  def test_element_always_returns_false
    assert_equal false, WINDOW.blank?
    assert_equal false, APP.blank?
    assert_equal false, slider.blank?
  end

  # other objects do not implement the method because it is not
  # useful for them to

end
