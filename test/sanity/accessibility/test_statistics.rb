require 'test/runner'
require 'accessibility/statistics'

class TestAccessibilityStatistics < MiniTest::Unit::TestCase

  def setup
    @stats = Accessibility::Statistics.new
    @q     = @stats.instance_variable_get :@q
    @s     = @stats.instance_variable_get :@stats
  end

  def test_global_constant
    assert_instance_of Accessibility::Statistics, STATS
  end

  def test_collects_stats
    assert_equal 0, @s[:pie]
    assert_equal 0, @s[:cake]
    @stats.increment :cake
    @q.sync { }
    assert_equal 1, @s[:cake]
    assert_equal 0, @s[:pie]
    @stats.increment :cake
    @q.sync { }
    assert_equal 2, @s[:cake]
    assert_equal 0, @s[:pie]
    @stats.increment :pie
    @q.sync { }
    assert_equal 2, @s[:cake]
    assert_equal 1, @s[:pie]
  end

  def test_concurrency
    loops = 1_000_000
    loops.times do @stats.increment :pie end
    @q.sync { }
    assert_equal loops, @s[:pie]
  end

  def test_to_s
    100.times do @stats.increment :cake                end
    2.times   do @stats.increment :pie                 end
    50.times  do @stats.increment :long_attribute_name end
    expected = <<-EOS
######################
# AX Call Statistics #
######################
cake...................100
long_attribute_name.....50
pie......................2
    EOS
    assert_equal expected, @stats.to_s
  end

  # @todo bench_increment

end
