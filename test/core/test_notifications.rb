class TestAXNotifications < TestCore

  def active_app
    active_app = APPS.find { |app| app.active? }
    AXUIElementCreateApplication(active_app.processIdentifier)
  end

  def menu_bar_item_for app
    name          = attribute_for app, KAXTitleAttribute
    menu_bar_item = children_for attribute_for(app, KAXMenuBarAttribute)
    menu_bar_item.find { |item| attribute_for(item, KAXTitleAttribute) == name }
  end

  # this test should be split up
  def test_yielded_proper_objects
    element      = nil
    notification = nil
    time         = 2.0
    app          = active_app
    menu         = menu_bar_item_for app

    AX.register_for_notif(app, KAXMenuOpenedNotification) do |el,notif|
      element      = el
      notification = notif
    end

    action_for menu, KAXPressAction
    AX.wait_for_notif(time)

    assert_kind_of AX::Element, element
    assert_kind_of NSString, notification

    AX.register_for_notif(app, KAXMenuClosedNotification)

    start = Time.now
    action_for menu, KAXCancelAction

    assert AX.wait_for_notif(time)
    assert_in_delta Time.now, start, time
  end

  def test_follows_block_return_value_when_false
    app  = active_app
    time = 0.1
    menu = menu_bar_item_for app

    AX.register_for_notif(app, KAXMenuOpenedNotification) do |_,_| false end
    action_for menu, KAXPressAction

    start = Time.now
    AX.wait_for_notif(time)
    refute_in_delta Time.now, start, time

    action_for menu, KAXCancelAction # cleanup
  end

  def test_waits_the_given_timeout
    time  = 0.1
    start = Time.now
    wait time
    assert_in_delta time, (Time.now - start), 0.05
  end

  def test_callbacks_are_unregistered_when_a_timeout_occurs
    skip 'This feature is not implemented yet'
  end

end
