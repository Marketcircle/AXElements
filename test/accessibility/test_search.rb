class TestSearch < TestAX

  APP = AX::Application.new REF

  def setup
    @search = Accessibility::Search.new APP
  end

  def test_search_finds_things_one_level_deep
    assert_equal APP.attribute(:main_window), @search.find(:StandardWindow, {})
  end

  def test_search_finds_things_two_levels_deep
    expected = APP.attribute(:main_window).attribute(:close_button)
    assert_equal expected, @search.find(:CloseButton, {})
  end

  def test_search_finds_stuff_event_with_no_filters
    assert_equal APP.attribute(:menu_bar), @search.find(:MenuBar, {})
  end

  def test_search_finds_with_a_filter
    assert_equal 'Yes', @search.find(:Button, title: 'Yes').attribute(:title)
    assert_equal 'No',  @search.find(:Button, title: 'No').attribute(:title)
    assert_equal 'Maybe So', @search.find(:Button, enabled: false).attribute(:title)
  end

  def test_search_uses_all_filters
    assert_nil @search.find(:Button, title: 'Maybe So', enabled: true)
    assert_equal 'Yes', @search.find(:Button, title: 'Yes', enabled: true).attribute(:title)
    assert_equal 'No',  @search.find(:Button, title: 'No').attribute(:title)
  end

  def test_find_returns_element_when_found
    button = @search.find(:Button, {})
    assert_kind_of AX::Button, button
  end

  def test_find_returns_nil_when_nothing_found
    assert_nil @search.find(:WhatYouCallIt, {})
  end

  def test_find_all_returns_array_with_elements_with_found
    buttons = @search.find_all(:Button, {})
    assert_kind_of NSArray, buttons
    assert_kind_of AX::Button, buttons.first
  end

  def test_find_all_returns_empty_array_when_nothing_found
    assert_empty @search.find_all(:WhatYouCallIt, {})
  end

  def test_filter_is_attribute_not_available_on_all_instances
    ret = @search.find_all(:Button, subrole: KAXCloseButtonSubrole)
    assert_equal 1, ret.size
  end

  def test_searching_for_superclass_will_also_find_subclasses_as_well
    ret = @search.find_all(:Button, {}).map &:class
    assert_includes ret, AX::CloseButton
    assert_includes ret, AX::FullScreenButton
    assert_includes ret, AX::SortButton
  end

  def test_searching_for_subclasses_will_not_find_superclasses
    ret = @search.find_all(:FullScreenButton, {})
    assert_equal 1, ret.size
    assert_instance_of AX::FullScreenButton, ret.first
  end

  def test_title_ui_element_filtering
    expected = APP.attribute(:main_window)

    # this test is kind of lame since we only have one window

    # case 1: classes match
    text = expected.attribute(:children).find do |child|
      child.class == AX::StaticText
    end
    actual = @search.find(:Window, title_ui_element: text)
    assert_equal expected, actual

    # case 2: classes do not match
    actual = @search.find(:Window, title_ui_element: 'AXElementsTester')
    assert_equal expected, actual
  end

  def test_table_header_filtering
    area  = APP.attribute(:main_window).attribute(:children).find do |child|
      child.class == AX::ScrollArea &&
        child.attributes.include?(KAXIdentifierAttribute) &&
        child.attribute(:identifier) == 'table'
    end
    table = area.children.find do |child|
      child.class == AX::Table
    end
    @search = Accessibility::Search.new APP.attribute(:main_window)

    # case 1: classes match
    column        = table.attribute(:columns).first
    button        = column.attribute(:header)
    search_result = @search.find(:Column, header: button)
    assert_equal column, search_result

    # case 2: classes do not match
    assert_equal 'One', @search.find(:Column, header: 'One').attribute(:header).attribute(:title)
  end

  def test_true_false_class_mismatch
    # since search does a class comparison to try and infer things,
    # it does not work with boolean values since they have different
    # classes, so we have another workaround for that case
    assert_nil @search.find(:Button, title: 'Maybe So', enabled: true)
    assert_nil @search.find(:Button, title: 'Yes',      enabled: false)
  end

  def test_nil_attribute_is_handled_as_special_case
    # some attributes store nil as their value, but the filter
    # might have been expecting string types

    # case 0: expected and actual are nil
    assert_equal APP.attribute(:main_window), @search.find(:Window, default_button: nil)

    # case 1: actual value is nil does not explode
    button = APP.attribute(:main_window).attribute(:close_button)
    assert_nil @search.find(:Window, default_button: button)

    # case 2: expected value is nil does not explode
    assert_nil @search.find(:Button, parent: nil)
  end

end
