require 'test/integration/helper'

class TestAXApplication < MiniTest::Unit::TestCase

  def app
    @app ||= AX::Application.new REF
  end

  def running_app
    @app.instance_variable_get :@app
  end

  def test_initialize_args
    assert_equal app, AX::Application.new(PID)
    assert_equal app, AX::Application.new(APP_BUNDLE_IDENTIFIER)
    assert_equal app, AX::Application.new(running_app.localizedName)
    assert_equal app, AX::Application.new(running_app)
  end

  def test_can_set_focus_and_blur_app # lol, blur
    assert app.set :focused, false
    refute app.active?
    refute app.attribute :focused
    refute app.attribute :focused?

    assert app.set :focused, true
    assert app.active?
    assert app.attribute :focused
    assert app.attribute :focused?

  ensure
    running_app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_can_hide_and_unhide_app
    assert app.set :hidden, true
    assert app.hidden?

    assert app.set :hidden, false
    refute app.hidden?

    assert app.perform :hide
    assert app.hidden?

    assert app.perform :unhide
    refute app.hidden?

  ensure
    running_app.activateWithOptions NSApplicationActivateIgnoringOtherApps
  end

  def test_set_calls_super
    assert app.set(:enhanced_user_interface, true)
  end

  def test_element_at_point
    button = app.main_window.close_button
    assert_equal button, app.element_at_point(button)
  end

end
