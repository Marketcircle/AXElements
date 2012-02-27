# -*- coding: utf-8 -*-

class TestAXApplication < MiniTest::Unit::TestCase

  def app
    @app ||= AX::Application.new REF
  end

  def running_app
    @running_app ||=
      NSRunningApplication.runningApplicationWithProcessIdentifier app.pid
  end

  def test_is_a_direct_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  def test_caches_running_app
    assert_instance_of NSRunningApplication, running_app
  end

  def test_can_set_focus_and_blur_app # lol, blur
    assert app.set :focused, to: false
    refute app.active?
    refute app.attribute :focused
    refute app.attribute :focused?

    assert app.set :focused, to: true
    assert app.active?
    assert app.attribute :focused
    assert app.attribute :focused?

  ensure
    running_app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_can_hide_and_unhide_app
    assert app.set :hidden, to: true
    assert app.hidden?

    assert app.set :hidden, to: false
    refute app.hidden?

    assert app.perform :hide
    assert app.hidden?

    assert app.perform :unhide
    refute app.hidden?

  ensure
    running_app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_inspect_includes_pid
    assert_match /\spid=\d+/, app.inspect
  end

  def test_inspect_includes_focused
    assert_match /\sfocused\[(?:✔|✘)\]/, app.inspect
  end

  def test_terminate_kills_app
    skip 'Not sure how to reset state after this test...'
    assert AX::DOCK.terminate
  end

  def test_overrides_call_super
    assert_equal 'AXElementsTester', app.title
    assert_match app.inspect, /children/

    called_super = false
    app.define_singleton_method :perform do |name|
      called_super = true if name == :some_action
    end
    app.perform :some_action
    assert called_super


    called_super = false
    app.define_singleton_method :'set:to:' do |attr, value|
      called_super = true if attr == :thingy && value == 'pie'
    end
    app.set :thingy, to: 'pie'
    assert called_super
  end

  def test_keydown
    got_callback = false
    app.define_singleton_method :'post:to:' do |events, ref|
      if events[0][1] == true && events.size == 1 && ref == REF
        got_callback = true
      end
    end
    app.keydown "\\OPTION"
    assert got_callback
  end

  def test_keyup
    got_callback = false
    app.define_singleton_method :'post:to:' do |events, ref|
      if events[0][1] == false && events.size == 1 && ref == REF
        got_callback = true
      end
    end
    app.keyup "\\OPTION"
    assert got_callback
  end

  def test_type_string_forwards_events
    got_callback = false
    app.define_singleton_method :'post:to:' do |events, ref|
      got_callback = true if events.kind_of?(Array) && ref == REF
    end
    app.type_string 'test'
    assert got_callback
  end

  def test_element_at_point
    button = app.main_window.close_button
    point  = button.to_point
    assert_equal button, app.element_at_point(*point.to_a)
  end

  def test_bundle_identifier
    assert_equal APP_BUNDLE_IDENTIFIER, app.bundle_identifier
  end

  def test_dock_constant_is_set
    assert_instance_of AX::Application, AX::DOCK
    assert_equal 'Dock', AX::DOCK.title
  end

end
