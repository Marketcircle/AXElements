require 'minitest/ax_elements'

class TestMiniTestAssertions < MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new PID
  end

  def test_methods_are_loaded
    assert_respond_to self, :assert_has_child
    assert_respond_to self, :assert_has_descendent
    assert_respond_to self, :refute_has_child
    assert_respond_to self, :refute_has_descendent
  end

  def test_assert_has_child
    expected = app.window

    assert_equal expected, assert_has_child(app,:window)
    assert_equal expected, assert_has_child(app,:window,title: 'AXElementsTester')

    result = assert_has_child(app,:window) { |x| 
      @got_called = true
      x.title == 'AXElementsTester'
    }
    assert_equal expected, result
    assert @got_called
  end

  def test_assert_has_child_raises_in_failure_cases
    e = assert_raises MiniTest::Assertion do
      assert_has_child app, :button
    end
    assert_match /to have button as a child/, e.message

    e = assert_raises MiniTest::Assertion do
      assert_has_child app, :button, title: 'Press Me'
    end
    assert_match /to have button\(title: "Press Me"\) as a child/, e.message
  end

  def test_assert_has_descendent
    expected = app.main_window.check_box

    assert_equal expected, assert_has_descendent(app,:check_box)
    assert_equal expected, assert_has_descendent(app,:check_box,title: /Box/)

    result = assert_has_descendent app, :check_box do |x|
      @got_called = true
      x.title == 'Unchecked Check Box'
    end
    assert_equal expected, result
    assert @got_called
  end

  def test_assert_has_descendent_raises_in_failure_cases
    ancestor = app.main_window.slider
    e        = assert_raises MiniTest::Assertion do
      assert_has_descendent ancestor, :window, title: /Cake/
    end
    assert_match /to have window\(title: \/Cake\/\) as a descendent/, e.message
  end

  def test_refute_has_child
    assert_nil refute_has_child(app,:button)
    assert_nil refute_has_child(app,:window,title: 'Herp Derp')

    result = refute_has_child app, :window do |x|
      @got_called = true
      x.title == 'Herp Derp'
    end
    assert_nil result
    assert @got_called
  end

  def test_refute_has_child_raises_in_failure_cases
    e = assert_raises MiniTest::Assertion do
      refute_has_child app, :window
    end
    assert_match /not to have window as a child/, e.message
  end

  def test_refute_has_descendent
    slider = app.main_window.slider

    assert_nil refute_has_descendent(slider,:window)
    assert_nil refute_has_descendent(slider,:element,title: 'Rhubarb')

    result = refute_has_descendent slider, :element do |x|
      @got_called = true
      x.attributes.include?(:title) && x.title == 'Rhubarb'
    end
    assert_nil result
    assert @got_called
  end

  def test_refute_has_descendent_raises_in_failure_cases
    e = assert_raises MiniTest::Assertion do
      refute_has_descendent app, :window
    end
    assert_match /not to have window as a descendent/, e.message

    e = assert_raises MiniTest::Assertion do
      refute_has_descendent app, :window do |_| true end
    end
    assert_match /window\[✔\]/, e.message
  end

end
