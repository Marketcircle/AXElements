class TestAXElement < MiniTest::Unit::TestCase

  def element
    @element ||= AX::Element.new REF
  end

  def test_methods_is_flat
    assert_equal element.methods, element.methods.flatten
  end

  def test_setting_through_method_missing
    got_callback = false
    element.define_singleton_method :'set:to:' do |attr, value|
      if attr == 'my_little_pony' && value == :firefly
        got_callback = true
      end
    end
    assert element.my_little_pony = :firefly
  end

end
