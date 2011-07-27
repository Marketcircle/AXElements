class TestSearch < TestAX

  APP = AX::Application.new REF

  def setup
    @search = Accessibility::Search.new APP
  end

  def test_search_one_level_deep
    assert_equal APP.attribute(:main_window), @search.find(:StandardWindow, {})
  end

  def test_search_two_levels_deep
    expected = APP.attribute(:main_window).attribute(:close_button)
    assert_equal expected, @search.find(:CloseButton, {})
  end

  def test_search_with_no_filters
    assert_equal APP.attribute(:menu_bar), @search.find(:MenuBar, {})
  end

  def test_search_with_one_filter
    assert_equal 'Yes', @search.find(:Button, title: 'Yes').attribute(:title)
    assert_equal 'No',  @search.find(:Button, title: 'No').attribute(:title)
    assert_equal 'Maybe So', @search.find(:Button, enabled: false).attribute(:title)
  end

  def test_search_with_two_filters
    assert_nil @search.find(:Button, title: 'Maybe So', enabled: true)
    assert_equal 'Yes', @search.find(:Button, title: 'Yes', enabled: true).attribute(:title)
    assert_equal 'No',  @search.find(:Button, title: 'No').attribute(:title)
  end

  def test_find_returns_element_when_found
  end

  def test_find_returns_nil_when_nothing_found
  end

  def test_find_all_returns_array_with_elements_with_found
  end

  def test_find_all_returns_empty_array_when_nothing_found
  end

  def test_filter_is_attribute_not_available_on_all_instances
    # might have to add an attribute to a button or something
  end

  def test_searching_for_superclass_will_also_find_subclasses_as_well
  end

  def test_searching_for_subclasses_will_not_find_superclasses
  end

  def test_title_ui_element_filtering
    # case 1: classes match
    # case 2: classes do not match
  end

  def test_true_false_class_mismatch
    # since search does a class comparison to try and infer things,
    # it does not work with boolean values since they have different
    # classes, so we have another workaround for that case
    assert_nil @search.find(:Button, title: 'Maybe So', enabled: true)
    assert_nil @search.find(:Button, title: 'Yes',      enabled: false)
  end

  def test_attribute_is_nil_is_handled_as_special_case
    # some attributes store nil as their value, but the filter
    # might have been expecting string types
  end

end
