require 'test/integration/helper'
require 'minitest/ax_elements'

class TestMiniTestAssertions < MiniTest::Unit::TestCase

  def test_assert_has_child
    expected = app.window

    assert_equal expected, assert_has_child(app, :window)
    assert_equal expected, assert_has_child(app, :window, title: 'AXElementsTester')

    assert_has_child(app, :window) { |_| @got_called = true }
    assert @got_called
  end

  def test_assert_has_child_raises_in_failure_cases
    e = assert_raises(MiniTest::Assertion) { assert_has_child app, :button }
    assert_match /to have Button as a child/, e.message

    e = assert_raises(MiniTest::Assertion) { assert_has_child app, :button, title: "Press" }
    assert_match %r{to have Button\(title: "Press"\) as a child}, e.message
  end

  def test_assert_has_descendent
    expected = app.main_window.check_box

    assert_equal expected, assert_has_descendent(app,:check_box)
    assert_equal expected, assert_has_descendent(app,:check_box, title: /Box/)

    assert_has_descendent(app, :check_box) { |_| @got_called = true }
    assert @got_called
  end

  def test_assert_has_descendent_raises_in_failure_cases
    e = assert_raises(MiniTest::Assertion) {
      assert_has_descendent(app.main_window.slider, :window, title: /Cake/)
    }
    assert_match /to have Window\(title: \/Cake\/\) as a descendent/, e.message
  end

  def test_assert_shortly_has
    assert_equal app.window, assert_shortly_has(:window, parent: app)
    assert_equal app.check_box, assert_shortly_has(:check_box, ancestor: app)

    assert_shortly_has(:window, parent: app) { @got_called = true }
    assert @got_called
  end

  def test_assert_shortly_has_raises_in_failure_cases
    e = assert_raises(MiniTest::Assertion) { assert_shortly_has(:button, parent: app, timeout: 0) }
    assert_match /to have child Button before a timeout occurred/, e.message

    e = assert_raises(MiniTest::Assertion) { assert_shortly_has(:table, ancestor: app.menu_bar_item, timeout: 0) }
    assert_match /to have descendent Table before a timeout occurred/, e.message
  end

  def test_refute_has_child
    assert_nil refute_has_child(app, :button)
    assert_nil refute_has_child(app, :window, title: 'Herp Derp')

    result = refute_has_child(app, :window) { |x| x.title == 'Herp Derp' }
    assert_nil result
  end

  def test_refute_has_child_raises_in_failure_cases
    e = assert_raises(MiniTest::Assertion) { refute_has_child app, :window }
    assert_match /NOT to have #{Regexp.escape(app.window.inspect)} as a child/, e.message
  end

  def test_refute_has_descendent
    slider = app.main_window.slider

    assert_nil refute_has_descendent(slider, :window)
    assert_nil refute_has_descendent(slider, :element, title: 'Rhubarb')

    result = refute_has_descendent slider, :element do |x|
      @got_called = true
      x.attributes.include?(:title) && x.title == 'Rhubarb'
    end
    assert_nil result
    assert @got_called
  end

  def test_refute_has_descendent_raises_in_failure_cases
    e = assert_raises(MiniTest::Assertion) { refute_has_descendent app, :window }
    assert_match /#{Regexp.escape(app.window.inspect)} as a descendent/, e.message
  end

end
