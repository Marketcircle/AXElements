class TestAXSystemWide < MiniTest::Unit::TestCase
  include Accessibility::Core

  def system
    AX::SystemWide.new
  end

  def test_is_effectively_a_singleton
    assert_equal system, system
  end

  def test_type_string_forwards_events
    element = system
    got_callback = false
    element.define_singleton_method :'post:to:' do |events, ref|
      got_callback = true if events.kind_of?(Array) && ref = REF
    end
    element.type_string 'test'
    assert got_callback
  end

  def test_search_not_allowed
    assert_raises NoMethodError do
      system.search
    end
  end

  def test_notifications_not_allowed
    assert_raises NoMethodError do
      system.search
    end
  end

  def test_element_at_point
    [[10,10],[100,100],[500,500],[800,600]].each do |point|
      expected = element_at_point point.first, and: point.second, for: system.ref
      actual   = system.element_at_point *point
      assert_equal expected, actual.ref
    end
  end

end
