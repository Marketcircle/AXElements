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
    box.set :value, to: 'okey dokey lemon pokey'

    box.set :selected_text_range, to: 0..5
    assert_equal CFRangeMake(0,6), box.selected_text_range

    box.set :selected_text_range, to: 1..5
    assert_equal CFRangeMake(1,5), box.selected_text_range

    box.set :selected_text_range, to: 5...10
    assert_equal CFRangeMake(5,5), box.selected_text_range

    box.set :selected_text_range, to: 1..-1
    assert_equal CFRangeMake(1,21), box.selected_text_range

    box.set :selected_text_range, to: 4...-10
    assert_equal CFRangeMake(4,8), box.selected_text_range

  ensure
    box.set :value, to: '' if box
  end

end
