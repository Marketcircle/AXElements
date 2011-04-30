class TestNSArrayMethodMissing < MiniTest::Unit::TestCase

  ELEMENTS = AX::DOCK.list.application_dock_items

  def test_delegates_up_if_array_is_not_composed_of_elements
    assert_raises NoMethodError do [1].title_ui_element end
  end

  def test_simple_attribute
    refute_empty ELEMENTS.url.compact
  end

  def test_artificially_plural_attribute
    refute_empty ELEMENTS.urls.compact
  end

  def test_naturally_plural_attribute
    refute_empty ELEMENTS.children.compact
  end

  def test_predicate_method
    refute_empty ELEMENTS.application_running?.compact
  end

end
