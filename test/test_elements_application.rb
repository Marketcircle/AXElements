class TestAXApplication < TestAX

  APP = AX::Application.new(AXUIElementCreateApplication(pid_for(APP_BUNDLE_IDENTIFIER)))

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

end


class TestAXApplicationSetAttribute < TestAXApplication

  def test_set_attribute_has_special_case_for_focus
    was_called = false
    dup_dock   = APP.dup
    dup_dock.send(:define_method, :set_focus) do
      was_called = true
    end
    dup_dock.set_attribute :focused, true
    assert was_called
  end

  def test_can_set_focus_to_an_app
    AX::DOCK.set_attribute(:focused, true)
    refute APP.attribute(:focused)
    APP.set_attribute(:focused, true)
    assert APP.attributes(:focused)
  end

end


class TestAXApplicationInspect < TestAXApplication

  def test_inspect_includes_pid
    assert_match /\s@pid=/, APP.inspect
  end

end


class TestAXApplicationTypeString < TestAXApplication

  def test_forwards_call
    class << AX
      alias_method :old_keyboard_action, :keyboard_action
      def keyboard_action element, string
        true if string == 'test' && element == APP_REF
      end
    end
    assert APP.type_string('test')
  ensure
    class << AX
      alias_method :keyboard_action, :old_keyboard_action
    end
  end

end


class TestAXApplicationTerminate < TestAXApplication

  # this test is a hack that kills the dock and relies on it
  # to start itself up again
  def test_kills_app
    assert AX::DOCK.terminate
    assert_nil AX::DOCK.instance_variable_get(:@ref)
    AX::DOCK.instance_variable_set(
                                   :@ref,
                                   AXUIElementCreateApplication(pid_for('com.apple.dock'))
                                   )
  end

end
