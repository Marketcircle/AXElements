class TestAccessibilityErrors < MiniTest::Unit::TestCase

  def test_lookup_failure_shows_inspect_output_of_arguments
    e = Accessibility::LookupFailure.new(:element, :name)
    assert_match /:name was not found for :element/, e.message

    o = Object.new
    def o.inspect; '"I am an object"'; end
    e = Accessibility::LookupFailure.new(o, [1,2,3])
    assert_match /\[1, 2, 3\] was not found for "I am an object"/, e.message
  end

  def test_lookup_failue_is_kind_of_arg_error
    assert_includes Accessibility::LookupFailure.ancestors, ArgumentError
  end

  def test_search_failure_shows_arguments
    e = Accessibility::SearchFailure.new(AX::DOCK, :list, {herp: :derp})
    assert_match /Could not find `list\(herp: :derp\)`/, e.message
    assert_match /as a child of AX::Application/, e.message
    assert_match /Element Path:\n\t\#<AX::Application/, e.message

    e = Accessibility::SearchFailure.new(AX::DOCK, :list, {})
    assert_match /Could not find `list`/, e.message

    e = Accessibility::SearchFailure.new(AX::DOCK, :list, nil)
    assert_match /Could not find `list`/, e.message
  end

  def test_search_failure_shows_element_path
    l = AX::DOCK.children.first
    e = Accessibility::SearchFailure.new(l, :trash_dock_item, nil)
    assert_match /AX::Application/, e.message
    assert_match /AX::List/, e.message
  end

  def test_search_failure_is_kind_of_no_method_error
    assert_includes Accessibility::SearchFailure.ancestors, NoMethodError
  end

end
