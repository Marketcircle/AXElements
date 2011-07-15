# -*- coding: utf-8 -*-
class TestAXApplication < TestAX

  APP = AX::Application.new(REF)

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  def test_app_is_the_equivalent_nsrunningapplication
    assert_equal APP_BUNDLE_IDENTIFIER, APP.app.bundleIdentifier
  end

  def test_can_set_focus_to_an_app
    APP.app.hide
    sleep 0.3
    refute APP.active?, 'App failed to hide'
    APP.set_attribute(:focused, true)
    sleep 0.3
    assert APP.active?, 'App failed to focus'
  ensure
    APP.app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_can_hide_the_app
    APP.set_attribute(:focused, false)
    sleep 0.3
    refute APP.active?, 'App failed to hide'
  ensure
    APP.app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_attribute_has_special_case_for_focused
    assert_instance_of_boolean APP.attribute(:focused?)
    assert_instance_of_boolean APP.attribute(:focused)
  end

  def test_attribute_still_works_for_other_attributes
    assert_equal 'AXElementsTester', APP.title
  end

  def test_inspect_includes_pid
    assert_match /\spid=\d+/, APP.inspect
  end

  def test_inspect_includes_focused
    assert_match /\sfocused\[(?:✔|✘)\]/, APP.inspect
  end

  def test_type_string_forwards_call
    class << AX
      alias_method :old_keyboard_action, :keyboard_action
      def keyboard_action element, string
        true if string == 'test' && element == TestAX::REF
      end
    end
    assert APP.type_string('test')
  ensure
    class << AX; alias_method :keyboard_action, :old_keyboard_action; end
  end

  def test_terminate_kills_app
    skip 'Not sure how to reset state after this test...'
    assert AX::DOCK.terminate
  end

end
