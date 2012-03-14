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

  def test_assert_has_child_raises_in_failure_case
    e = assert_raises MiniTest::Assertion do
      assert_has_child app, :button
    end
    assert_match /to have button as a child/, e.message

    e = assert_raises MiniTest::Assertion do
      assert_has_child app, :button, title: 'Press Me'
    end
    assert_match /to have button\(title: "Press Me"\) as a child/, e.message
  end

end
