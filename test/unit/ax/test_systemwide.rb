class TestAXSystemWide < MiniTest::Unit::TestCase

  def test_is_effectively_a_singleton
    assert_equal system_wide, system_wide
  end

  def test_keydown
    element = system_wide
    got_callback = false
    element.define_singleton_method :'post:to:' do |events, ref|
      if events[0][1] == true && events.size == 1 && ref == element.ref
        got_callback = true
      end
    end
    element.keydown "\\OPTION"
    assert got_callback
  end

  def test_keyup
    element = system_wide
    got_callback = false
    element.define_singleton_method :'post:to:' do |events, ref|
      if events[0][1] == false && events.size == 1 && ref == element.ref
        got_callback = true
      end
    end
    element.keyup "\\OPTION"
    assert got_callback
  end

  def test_type_string_forwards_events
    element = system_wide
    got_callback = false
    element.define_singleton_method :'post:to:' do |events, ref|
      got_callback = true if events.kind_of?(Array) && ref == element.ref
    end
    element.type_string 'test'
    assert got_callback
  end

  def test_search_not_allowed
    assert_raises NoMethodError do
      system_wide.search
    end
  end

  def test_notifications_not_allowed
    assert_raises NoMethodError do
      system_wide.search
    end
  end

  def test_element_at_point
    element = system_wide
    extend Accessibility::Core

    [[10,10],[100,100],[500,500],[800,600]].each do |point|
      expected = element_at point, for: element.ref
      actual   = element.element_at_point *point
      assert_equal expected, actual.ref
    end
  end

end
