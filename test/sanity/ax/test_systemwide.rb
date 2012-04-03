require 'test/helper'
require 'ax/systemwide'

class AX::Element
  attr_reader :ref
end

class TestAXSystemWide < MiniTest::Unit::TestCase

  def system_wide
    @system_wide ||= AX::SystemWide.new
  end

  def test_is_effectively_a_singleton
    assert_equal AX::SystemWide.new, AX::SystemWide.new
  end

  def test_type_string_forwards_events
    system  = system_wide.ref
    meth    = system.method :post
    got_callback = false
    system.define_singleton_method :post do |events|
      got_callback = true if events.kind_of?(Array)
    end
    system_wide.type_string 'test'
    assert got_callback
  ensure
    system.define_singleton_method :post, meth if meth
  end

  def test_search_not_allowed
    assert_raises(NoMethodError) { system_wide.search }
  end

  def test_notifications_not_allowed
    assert_raises(NoMethodError) { system_wide.on_notification }
  end

  def test_element_at
    system = system_wide.ref
    [[10,10],[500,500]].each do |point|
      expected = system.element_at(point)
      actual   = system_wide.element_at(point).ref
      assert_equal expected, actual
    end
  end

  def test_parameterized_attributes_is_empty
    assert_empty system_wide.parameterized_attributes
  end

  def test_actions_is_empty
    assert_empty system_wide.actions
  end

  # this is a special case because it hits other things, like
  # parameterized attributes, which do not work with the
  # system wide object
  def test_respond_to
    assert_respond_to system_wide, :role
    assert_respond_to system_wide, :role=
    assert_respond_to system_wide, :inspect
    assert_respond_to system_wide, :object_id
  end

end
