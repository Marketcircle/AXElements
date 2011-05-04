class TestAXApplication < TestElements

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  def test_application_with_bundle_identifier
    [ ['com.apple.dock'], ['com.apple.dock', 2] ].each do |args|
      app = AX::Application.application_with_bundle_identifier *args
      assert_instance_of AX::Application, app
      assert_equal 'Dock', app.attribute(KAXTitleAttribute)
    end
  end

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

  # @note This test uses a stub
  def test_type_string
    class << AX
      alias_method :old_keyboard_action, :keyboard_action
      attr_reader :test_type_string_mock
      def keyboard_action element, string
        true if string == 'test'
      end
    end
    assert EL_DOCK.type_string('test')
  ensure
    class << AX
      alias_method :keyboard_action, :old_keyboard_action
    end
  end

end
