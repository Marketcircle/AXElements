require 'rubygems'
require 'AXElements'

gem 'minitest-macruby-pride'
require 'minitest/autorun'
require 'minitest/benchmark'

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
