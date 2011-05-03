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
  end

end


class BenchSearch < TestElements

  def bench_no_extra_filters
  end

  def bench_simple_filter
  end

  def bench_multiple_filters
  end

  def bench_shallow_search
  end

  def bench_deep_search
  end

end
