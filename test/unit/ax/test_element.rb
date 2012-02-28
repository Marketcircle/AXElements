class TestAXElement < MiniTest::Unit::TestCase

  def element
    @element ||= AX::Element.new REF
  end

  def test_methods_is_flat
    assert_equal element.methods, element.methods.flatten
  end
  end

end
