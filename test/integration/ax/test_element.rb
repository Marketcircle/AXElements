require 'test/integration/helper'

class TestAXElement < MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new PID
  end

  def test_search_singular_returns_array
    result = app.search(:window)
    assert_kind_of AX::Window, result
  end

  def test_search_plural
    result = app.search(:windows)
    assert_kind_of NSArray, result
  end

  def test_set_range
    box = app.window.text_area
    box.set :value, 'okey dokey lemon pokey'

    box.set :selected_text_range, 0..5
    assert_equal 0..5, box.selected_text_range

    box.set :selected_text_range, 1..5
    assert_equal 1..5, box.selected_text_range

    box.set :selected_text_range, 5...10
    assert_equal 5..9, box.selected_text_range

    box.set :selected_text_range, 1..-1
    assert_equal 1..21, box.selected_text_range

    box.set :selected_text_range, 4...-10
    assert_equal 4..11, box.selected_text_range

  ensure
    box.set :value, '' if box
  end

end
