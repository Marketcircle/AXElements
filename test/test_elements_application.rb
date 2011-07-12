class TestAXApplication < TestAX

  APP = AX::Application.new(APP_REF)

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  def test_app_is_the_equivalent_nsrunningapplication
    assert_equal APP_BUNDLE_IDENTIFIER, APP.app.bundleIdentifier
  end

  def test_can_set_focus_to_an_app
    app = AX::DOCK.attribute(:children).first.attribute(:children).find do |item|
      item.class == AX::ApplicationDockItem
    end
    app.perform_action(:press)
    refute APP.active?
    APP.set_attribute(:focused, true)
    sleep 0.2
    assert APP.active?
  end

  def test_attribute_has_special_case_for_focused
    assert APP.attribute(:focused?)
    assert APP.attribute(:focused)
  end

  def test_attribute_still_works_for_other_attributes
    assert_equal 'AXElementsTester', APP.title
  end

  def test_inspect_includes_pid
    assert_match /\spid=\d+/, APP.inspect
  end

  def test_inspect_includes_focused
    assert_match /\sfocused=\[✓\]/, APP.inspect
    assert_match /\sfocused=\[✘\]/, AX::DOCK.inspect
  end

  def test_type_string_forwards_call
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

  def test_terminate_kills_app
    skip 'Not sure how to reset state after this test...'
    assert AX::DOCK.terminate
  end

end
