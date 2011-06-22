require 'rubygems'
gem     'minitest-macruby-pride', '>= 2.2'
require 'minitest/autorun'
require 'minitest/benchmark'

$LOAD_PATH.unshift './lib'
require 'AXElements'

class BenchBase < MiniTest::Unit::TestCase
  def self.bench_range
    bench_exp 10, 10_000
  end

  def bench
    assert_performance_linear { |n| n.times { yield } }
  end

  DOCK_LIST = AX::DOCK.list
  DOCK_ITEM = AX::DOCK.application_dock_item
end

class BenchSuperDirect < BenchBase
  def bench_string
    bench { AX::DOCK.attribute(KAXTitleAttribute) }
  end
  def bench_boolean
    bench { DOCK_ITEM.attribute(KAXSelectedAttribute) }
  end
  def bench_element
    bench { DOCK_LIST.attribute(KAXChildrenAttribute) }
  end
  def bench_boxed
    bench { DOCK_ITEM.attribute(KAXPositionAttribute) }
  end
  def bench_element
    bench { DOCK_ITEM.attribute(KAXParentAttribute) }
  end
  def bench_array
    bench { DOCK_LIST.attribute(KAXChildrenAttribute) }
  end
end

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


