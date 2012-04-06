require 'test/helper'
require 'ax/systemwide'

class AX::Element
  attr_reader :ref
end

class TestAXSystemWide < MiniTest::Unit::TestCase

  def system_wide
    @system_wide ||= AX::SystemWide.new
  end

  # this is more so I know if Apple ever changes how CFEqual() works on AX stuff
  def test_is_effectively_a_singleton
    assert_equal AX::SystemWide.new, AX::SystemWide.new
  end

  def test_type_forwards_events
    ref         = system_wide.ref
    called_back = false
    ref.define_singleton_method(:post) { |x| called_back = true if x.kind_of? Array }
    assert system_wide.type 'test'
    assert called_back
  end

  def test_search_not_allowed
    assert_raises(NoMethodError) { system_wide.search }
  end

  def test_notifications_not_allowed
    assert_raises(NoMethodError) { system_wide.on_notification }
  end

  def test_element_at # returns a wrapped dude
    assert_kind_of AX::Element, system_wide.element_at([10,10])
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
