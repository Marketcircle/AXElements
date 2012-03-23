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

  def test_set_range_with_negative_range
    skip
  end

end
