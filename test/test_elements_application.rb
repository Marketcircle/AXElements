class TestAXApplication < TestAX

  APP = AX::Application.new(APP_REF)

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

end


class TestAXApplicationSetAttribute < TestAXApplication

  def test_set_attribute_has_special_case_for_focus
    was_called = false
    dup_dock   = APP.dup
    dup_dock.define_singleton_method :set_focus do
      was_called = true
    end
    dup_dock.set_attribute :focused, true
    assert was_called
  end

  def test_can_set_focus_to_an_app
    app = AX::DOCK.attribute(:children).first.attribute(:children).find do |item|
      item.class == AX::ApplicationDockItem
    end
    app.perform_action(:press)
    refute APP.attribute(:main_window).attribute(:focused?)
    APP.set_attribute(:focused, true)
    sleep 0.2
    # @todo need to fix this test
    skip 'This test is broken'
    assert APP.attribute(:main_window).attribute(:focused?)
  end

  def test_set_focus_does_not_work_if_app_not_in_dock
    assert_raises RuntimeError do
      AX::DOCK.set_attribute(:focused, true)
    end
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
        true if string == 'test' && element == TestAX::APP_REF
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
    skip 'Crashes MacRuby right now, need to find out why'
    assert AX::DOCK.terminate
    assert_nil AX::DOCK.instance_variable_get(:@ref)
    AX::DOCK.instance_variable_set(
                                   :@ref,
                                   AXUIElementCreateApplication(pid_for('com.apple.dock'))
                                   )
  end

end
