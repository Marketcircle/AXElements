##
# Integration level tests that make sure search semantics are working,
# these are effectively the tests for Accessibility::Qualifier.
class TestSearchSemantics < TestAX

  def app
    @@app ||= AX::Application.new REF
  end

  def window
    @@window ||= app.attribute(:main_window)
  end

  def test_finds_things_one_level_deep
    assert_equal window, app.search(:standard_window)
  end

  def test_finds_things_two_levels_deep
    expected = app.attribute(:main_window).attribute(:close_button)
    assert_equal expected, app.search(:close_button)
  end

  def test_finds_even_with_no_filters
    assert_equal app.attribute(:menu_bar), app.search(:menu_bar)
  end

  def test_finds_with_a_filter
    assert_equal 'Yes', window.search(:button, title: 'Yes').attribute(:title)
    assert_equal 'No',  window.search(:button, title: 'No') .attribute(:title)
    assert_equal 'Maybe So', window.search(:button, enabled: false).attribute(:title)
  end

  def test_uses_all_filters
    assert_nil window.search(:button, title: 'Maybe So', enabled: true)
    assert_equal 'Yes', window.search(:button, title: 'Yes', enabled: true).attribute(:title)
  end

  def test_returns_element_when_found
    assert_kind_of AX::Button, window.search(:button)
    assert_kind_of AX::Button, window.search(:buttons).first
  end

  def test_returns_nil_when_nothing_found
    assert_nil   window.search(:what_you_call_it)
    assert_empty window.search(:what_you_call_its)
  end

  def test_searching_for_superclass_will_also_find_subclasses
    ret = window.search(:buttons).map &:class
    assert_includes ret, AX::CloseButton
    assert_includes ret, AX::FullScreenButton
    assert_includes ret, AX::SortButton
  end

  def test_searching_for_subclasses_will_not_find_superclasses
    ret = window.search(:full_screen_buttons)
    assert_equal 1, ret.size
    assert_instance_of AX::FullScreenButton, ret.first
  end

  def test_does_not_fault_when_element_does_not_respond_to_filter
    expected = window.attribute(:close_button)
    actual   = window.search(:button, subrole: KAXCloseButtonSubrole)
    assert_equal expected, actual
  end

  # @note test is kind of lame since we only have one window
  # @note this test exists for legacy purposes, the actual
  #       logic has since moved elsewhere but behavior should
  #       remain
  def test_title_ui_element_filtering
    # case 1: classes match
    text = window.attribute(:children).find do |child|
      child.class == AX::StaticText
    end
    actual = app.search(:window, title_ui_element: text)
    assert_equal window, actual

    # case 2: classes do not match
    actual = app.search(:window, title_ui_element: 'AXElementsTester')
    assert_equal window, actual
  end

  # @note this test exists for legacy purposes, the actual
  #       logic has since moved elsewhere but behavior should
  #       remain
  def test_table_header_filtering
    area  = window.attribute(:children).find do |child|
      child.class == AX::ScrollArea &&
        child.attributes.include?(KAXIdentifierAttribute) &&
        child.attribute(:identifier) == 'table'
    end
    table = area.attribute(:children).find { |child| child.class == AX::Table }

    # case 1: classes match
    column        = table.attribute(:columns).first
    button        = column.attribute(:header)
    search_result = table.search(:column, header: button)
    assert_equal column, search_result

    # case 2: classes do not match
    assert_equal 'One', table.search(:column, header: 'One').attribute(:header).attribute(:title)
  end

  # @note another legacy test
  def test_true_false_class_mismatch
    # since search does a class comparison to try and infer things,
    # it does not work with boolean values since they have different
    # classes, so we have another workaround for that case
    assert_nil window.search(:button, title: 'Maybe So', enabled: true)
    assert_nil window.search(:button, title: 'Really Long Button Title')
  end

  # @note another legacy test
  def test_nil_attribute_is_handled_as_special_case
    # some attributes store nil as their value, but the filter
    # might have been expecting string types, similar to how
    # we need to handle true/false classness...

    # case 0: expected and actual are nil
    assert_equal window, app.search(:window, default_button: nil)

    # case 1: actual value is nil does not explode
    button = window.attribute(:close_button)
    assert_nil app.search(:window, default_button: button)

    # case 2: expected value is nil does not explode
    assert_nil window.search(:button, parent: nil)
  end

  def test_nested_search
    # singular
    # plural
    # without filters
    # with filters
    # expected results
  end

end
