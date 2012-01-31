# be very careful about cleaning up state after notification tests
class TestAccessibilityCoreNotifications < MiniTest::Unit::TestCase
  include Accessibility::Core

  SHORT_TIMEOUT = 0.1
  TIMEOUT       = 1.0

  def window
    @@window ||= attr KAXMainWindowAttribute, for: REF
  end

  def child name
    children_for(window).find { |item| role_for(item) == name }
  end

  def yes_button
    @@yes_button ||= children_for(window).find do |item|
      if role_for(item) == KAXButtonRole
        attr(KAXTitleAttribute, for: item) == 'Yes'
      end
    end
  end

  def radio_group
    @@radio_group ||= child KAXRadioGroupRole
  end

  def radio_gaga
    @@gaga ||= children_for(radio_group).find do |item|
      attr(KAXTitleAttribute, for: item) == 'Gaga'
    end
  end

  def radio_flyer
    @@flyer ||= children_for(radio_group).find do |item|
      attr(KAXTitleAttribute, for: item) == 'Flyer'
    end
  end

  def measure_time
    start = Time.now
    yield
    Time.now - start
  end

  def teardown
    if value_for(radio_gaga) == 1
      perform KAXPressAction, for: radio_flyer
    end
    unregister_notifs
  end


  def test_break_if_ignoring
    register_to_receive KAXValueChangedNotification, from: radio_gaga do |_,_| true end
    perform KAXPressAction, for: radio_gaga
    time = measure_time { wait SHORT_TIMEOUT }
    assert time < SHORT_TIMEOUT
  end

  def test_break_if_block_returns_falsey
    register_to_receive KAXValueChangedNotification, from: radio_gaga do |_,_| false end
    perform KAXPressAction, for: radio_gaga
    time = measure_time { wait SHORT_TIMEOUT }
    assert time > SHORT_TIMEOUT
  end

  def test_stops_if_block_returns_truthy
    register_to_receive KAXValueChangedNotification, from: radio_gaga do |_,_| true end
    perform KAXPressAction, for: radio_gaga
    assert wait SHORT_TIMEOUT
  end

  def test_returns_triple
    observer, notif, element =
      register_to_receive KAXValueChangedNotification, from: radio_gaga do |_,_| true end
    assert_equal AXObserverGetTypeID(), CFGetTypeID(observer)
    assert_equal KAXValueChangedNotification, notif
    assert_equal radio_gaga, element
  end

  def test_wait_stops_waiting_when_notif_received
    register_to_receive KAXValueChangedNotification, from: radio_gaga do |_,_| true end
    perform KAXPressAction, for: radio_gaga
    time = measure_time { wait SHORT_TIMEOUT }
    assert time < 0.02, 'Might fail sometimes due to latency issues or high machine load'
  end

  def test_works_with_custom_notifs
    got_callback = false
    register_to_receive 'Cheezburger', from: yes_button do |_,_|
      got_callback = true
    end
    perform KAXPressAction, for: yes_button
    wait SHORT_TIMEOUT
    assert got_callback, 'did not get callback'
  end

  def test_unregistering_clears_notif
    triple = register_to_receive 'Cheezburger', from: yes_button do |_,_| true end
    assert_includes Accessibility::Core::NOTIFS.keys, triple.first
    unregister_notifs
    refute_includes Accessibility::Core::NOTIFS.keys, triple.first
  end

  def test_unregistering_noops_if_not_registered
    assert_block do
      5.times { unregister_notifs }
    end
  end

  def test_listening_to_app_catches_everything
    got_callback   = false
    register_to_receive KAXValueChangedNotification, from: REF do |_,_|
      got_callback = true
    end
    perform KAXPressAction, for: radio_gaga
    wait TIMEOUT
    assert got_callback
  end

end
