# -*- coding: utf-8 -*-
require 'test/helper'
require 'ax/application'

class AX::Element
  attr_reader :ref
end

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

  def test_inspect_includes_pid
    assert_match /\spid=\d+/, app.inspect
  end

  def test_inspect_includes_focused
    assert_match /\sfocused\[(?:✔|✘)\]/, app.inspect
  end

  def test_terminate
    got_called = false
    mock       = Object.new
    mock.define_singleton_method(:terminate)   { got_called = true }
    mock.define_singleton_method(:terminated?) { false }
    app.instance_variable_set :@app, mock
    app.perform :terminate
    assert got_called
  ensure
    app.instance_variable_set :@app, running_app
  end

  def test_force_terminate
    got_called = false
    mock       = Object.new
    mock.define_singleton_method(:forceTerminate) { got_called = true }
    mock.define_singleton_method(:terminated?   ) {             false }
    app.instance_variable_set :@app, mock

    app.perform :force_terminate
    assert got_called
  ensure
    app.instance_variable_set :@app, running_app
  end

  def test_overrides_call_super
    assert_match app.inspect, /children/
    assert_equal 'AXElementsTester', app.title

    called_super = false
    app.define_singleton_method :perform do |name|
      called_super = true if name == :some_action
    end
    app.perform :some_action
    assert called_super

    called_super = false
    app.define_singleton_method :set do |attr, value|
      called_super = true if attr == :thingy && value == 'pie'
    end
    app.set :thingy, 'pie'
    assert called_super
  end

  def test_type_string_forwards_events
    skip "This strangely causes other tests to fail occassionally"
    got_callback = false
    app.ref.define_singleton_method :post do |events|
      got_callback = true if events.kind_of?(Array)
    end
    app.type_string 'test'
    assert got_callback
  end

  def test_bundle_identifier
    assert_equal running_app.bundleIdentifier, app.bundle_identifier
  end

end
