class BenchDirect < BenchBase
  def bench_string
    bench { AX::DOCK.get_attribute(:title) }
  end
  def bench_boolean
    bench { DOCK_ITEM.get_attribute(:selected) }
  end
  def bench_array
    bench { DOCK_LIST.get_attribute(:children) }
  end
  def bench_boxed
    bench { DOCK_ITEM.get_attribute(:position) }
  end
  def bench_element
    bench { DOCK_ITEM.get_attribute(:parent) }
  end
end

class BenchMethodMissing < BenchBase
  def bench_string
    bench { AX::DOCK.title }
  end
  def bench_boolean
    bench { DOCK_ITEM.selected? }
  end
  def bench_array
    bench { DOCK_LIST.children }
  end
  def bench_boxed
    bench { DOCK_ITEM.position }
  end
  def bench_element
    bench { DOCK_ITEM.parent }
  end
end
