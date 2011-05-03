class MockApplication < AX::Application

  def initialize ref
    super
    @mock = MiniTest::Mock.new
    @mock.expect :keyboard_action, true, [ref, 'test']
  end

  attr_reader :mock
  alias_method :AX, :mock

end


class TestAXApplication < TestElements

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  # def test_application_with_bundle_identifier
  #   mock = MiniTest::Mock.new
  #   mock.expect :application_for_bundle_identifier, nil, ['com.test']
  #   mock.expect :application_for_bundle_identifier, nil, ['com.test', 9001]

  #   dup_class = AX::Application.dup
  #   dup_class.instance_eval do
  #     const_set( :AX, Module.new )
  #     AX.class_eval { const_set(:Singletons, mock) }
  #   end

  #   dup_class.application_with_bundle_identifier 'com.test'
  #   dup_class.application_with_bundle_identifier 'com.test', 9001

  #   mock.verify
  # end

  def test_set_attribute_has_special_case_for_focus
    was_called = false
    dup_class  = AX::Application.dup
    dup_class.class_eval do
      define_method :set_focus do was_called = true end
    end
    EL_DOCK.set_attribute :focused, true
    assert was_called
  end

  def test_inspect_includes_pid
    assert_match /\s@pid=/, AX::DOCK.inspect
  end

  def test_can_post_keyboard_events
    assert AX::Application.instance_methods.include?(:type_string)
  end

  def test_type_string
    ref  = EL_DOCK.instance_variable_get(:@ref)
    dock = MockApplication.new ref
    dock.type_string('test')
    dock.mock.verify
  end

end
