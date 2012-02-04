class TestAXElements < MiniTest::Unit::TestCase
 
  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert Object.const_defined? :KAXIdentifierAttribute
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

end
