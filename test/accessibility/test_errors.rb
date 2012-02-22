class TestAccessibiityErrors < MiniTest::Unit::TestCase

  def test_lookup_failure_shows_inspect_output_of_arguments
    e = Accessibility::LookupFailure.new(:element, :name)
    assert_match /:name was not found for :element/, e.message

    o = Object.new
    def o.inspect; '"I am an object"'; end
    e = Accessibility::LookupFailure.new(o, [1,2,3])
    assert_match /\[1, 2, 3\] was not found for "I am an object"/, e.message
  end

  def test_search_failure_shows_arguments
    skip
    #
    #
    e = Accessibility::SearchFailure.new(herp, derp, mcgurp)
  end

  def test_search_failure_shows_element_path
    skip
    e = Accessibility::SearchFailure.new
  end

end
