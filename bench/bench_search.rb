class BenchBareSearch < BenchBase

  def bench_one_level_deep
  end

  def bench_two_levels_deep
  end

  def bench_three_levels_deep
  end

  def bench_big_table
  end

  def bench_small_table
  end

end


class BenchSimpleFilters < BenchBase
end


class BenchIntelligentFilters < BenchBase
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
