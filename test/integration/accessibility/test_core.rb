class TestAccessibilityCore < MiniTest::Unit::TestCase

  # this assumes that radar://10040865 is not fixed
  # once it is fixed, this case becomes less of an
  # issue anyways
  def test_nil_children_returns_empty_array
    app  = app_with_name 'AXElementsTester'
    menu = app.menu_bar_item(title: 'Help')
    press menu

    assert_empty menu.search_field.children
  ensure
    cancel menu if menu
  end

  def test_size_of_is_zero_when_failure_occurs
    skip 'TODO: not sure how to trigger such a failure..'
  end

end
