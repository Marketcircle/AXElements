class TestSearch < TestElements

  def test_can_search
    assert AX::Element.instance_methods.include?(:search)
  end

  def test_search_one_level_deep
    assert_equal 'AX::List', AX::DOCK.search(:list).class.to_s
  end

  def test_search_multiple_levels_deep
    assert_equal 'AX::ApplicationDockItem', AX::DOCK.search(:application_dock_item).class.to_s
  end

  def test_search_works_with_plural
    ret = AX::DOCK.search(:lists)
    assert_instance_of Array, ret
    assert_instance_of AX::List, ret.first
  end

  def test_is_breadth_first
    skip 'This test needs a very specific window organization to test properly'
  end

  def test_nil_if_not_found_for_singular_search
    assert_nil AX::DOCK.search(:fake_thing)
  end

  def test_empty_array_for_plural_search
    assert_empty AX::DOCK.search(:fake_things)
  end

end


class BenchSearch < TestElements

# some interesting scenarios
#  searching a table with a lot of rows
#    in this test, our variable is the number of rows
#  search a tall tree
#    in this test, our variable is how tall the tree is
#  search with no filters
#    this is a simple case that should be thrown in as a
#    control, it will help gauge how much search performance
#    depends on the core implementation of the AX module
#  search with a lot of filters
#    this test will become more important as the filtering
#    logic becomes more complex due to supporting different
#    ideas (e.g. the :title_ui_element hack that exists in v0.4)

end
