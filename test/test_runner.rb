require 'rubygems'
gem     'minitest'
require 'minitest/autorun'

# preprocessor powers, assemble!
if ENV['BENCH']
  require 'minitest/benchmark'
else
  require'minitest/pride'
end


class MiniTest::Unit::TestCase

  # You may need this to help track down an issue if a test is crashing MacRuby
  # def self.test_order
  #   :alpha
  # end

  def self.bench_range
    bench_exp 100, 100_000
  end

end
