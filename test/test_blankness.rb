class TestBlankPredicate < TestAX

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
    app    = AX::Element.new REF, AX.attrs_of_element(REF)
    window = app.attribute(:main_window)
    assert_equal false, window.blank?
    assert_equal false, app.blank?
  end

  # other objects do not implement the method because it is not
  # useful for them to

end
