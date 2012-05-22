# -*- coding: utf-8 -*-
require 'test/helper'
require 'ax/application'


class TestAXApplication < MiniTest::Unit::TestCase

  def app
    @app ||= AX::Application.new REF
  end

  def running_app
    @running_app ||=
      NSRunningApplication.runningApplicationWithProcessIdentifier app.pid
  end

  def test_subclass_of_element
    assert_equal AX::Element, AX::Application.superclass
  end

  def test_inspect
    assert_match /children/, app.inspect
    assert_match /\spid=\d+/, app.inspect
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
  end

  def test_force_terminate
    got_called = false
    mock       = Object.new
    mock.define_singleton_method(:forceTerminate) { got_called = true }
    mock.define_singleton_method(:terminated?   ) {             false }
    app.instance_variable_set :@app, mock

    app.perform :force_terminate
    assert got_called
  end

  def test_writable_handles_focused_and_hidden
    assert app.writable? :focused?
    assert app.writable? :focused
    assert app.writable? :hidden
    assert app.writable? :hidden?
  end

  def test_attribute_calls_super
    assert_equal 'AXElementsTester', app.title
  end

  def test_set_calls_super
    called_super = false
    app.define_singleton_method :set do |attr, value|
      called_super = true if attr == :thingy && value == 'pie'
    end
    app.set :thingy, 'pie'
    assert called_super
  end

  def test_writable_calls_super
    called_super = false
    app.define_singleton_method :writable? do |attr|
      called_super = true if attr == :brain
    end
    app.writable? :brain
    assert called_super
  end

  def test_perform_calls_super
    called_super = false
    app.define_singleton_method :perform do |name|
      called_super = true if name == :some_action
    end
    app.perform :some_action
    assert called_super
  end

  def test_bundle_identifier
    assert_equal running_app.bundleIdentifier, app.bundle_identifier
  end

  def test_info_plist
    assert_equal 'hmmmmm.icns', app.info_plist['CFBundleIconFile']
  end

  def test_version
    assert_equal '1.0', app.version
  end

end
