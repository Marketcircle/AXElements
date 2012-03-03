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

  def test_respond_to_works_with_dynamic_setters
    window = element.attribute(:main_window)
    assert_respond_to window, :position=
    assert_respond_to window, :size=
    refute_respond_to window, :pie=
  end

end
