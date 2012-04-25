# -*- coding: utf-8 -*-
require 'test/integration/helper'
require 'rspec/expectations/ax_elements'

class TestRSpecMatchers < MiniTest::Unit::TestCase


  def test_have_child_should_failure_message
    e = app.main_window.slider
    m = have_child(:window)

    refute m.matches?(e)
    assert_equal "Expected #{e.inspect} to have child Window", m.failure_message_for_should
  end

  def test_have_child_should_not_failure_message
    e = app.window
    m = have_child(:window)

    refute m.does_not_match?(app)
    assert_equal "Expected #{app.inspect} to NOT have child #{e.inspect}", m.failure_message_for_should_not
  end

  def test_have_child_description
    m = have_child(:window) { }
    assert_equal 'should have a child that matches Window[✔]', m.description
  end



  def test_have_descendent_should_failure_message
    m = have_descendent(:button)
    e = app.main_window.slider

    refute m.matches?(e)
    assert_equal "Expected #{e.inspect} to have descendent Button", m.failure_message_for_should
  end

  def test_have_descendent_should_not_failure_message
    m = have_descendant(:window)
    e = app.window

    refute m.does_not_match?(app)
    assert_equal "Expected #{app.inspect} to NOT have descendent #{e.inspect}", m.failure_message_for_should_not
  end

  def test_have_descendent_description
    m = have_descendent(:button)
    assert_equal 'should have a descendent matching Button', m.description
  end



  def test_shortly_have_child_should_failure_message
    m = shortly_have_child(:button, timeout: 0) { }
    e = app.main_window.slider

    refute m.matches?(e)
    assert_equal "Expected #{e.inspect} to have child Button[✔] before a timeout occurred",
      m.failure_message_for_should
  end

  def test_shortly_have_child_should_not_failure_message
    m = shortly_have_child(:window)
    e = app

    refute m.does_not_match?(e)
    assert_equal "Expected #{e.inspect} to NOT have child #{e.window.inspect} before a timeout occurred",
      m.failure_message_for_should_not
  end

  def test_shortly_have_child_description
    m = shortly_have_child(:button)
    assert_equal 'should have a child that matches Button before a timeout occurs', m.description
  end



  def test_shortly_have_descendent_should_failure_message
    m = shortly_have_descendent(:button, timeout: 0)
    e = app.main_window.slider

    refute m.matches?(e)
    assert_equal "Expected #{e.inspect} to have descendent Button before a timeout occurred",
      m.failure_message_for_should
  end

  def test_shortly_have_descendent_should_not_failure_message
    m = shortly_have_descendent(:window)
    e = app

    refute m.does_not_match?(e)
    assert_equal "Expected #{e.inspect} to NOT have descendent #{e.window.inspect} before a timeout occurred",
      m.failure_message_for_should_not
  end

  def test_shortly_have_descendent_description
    m = shortly_have_descendent(:button)
    assert_equal 'should have a descendent matching Button before a timeout occurs', m.description
  end

end
