class TestAXElement < MiniTest::Unit::TestCase
  def test_can_click
    assert AX::Element.instance_methods.include?(:left_click)
  end
end

class TestAXElementClicking < MiniTest::Unit::TestCase
end
