require 'test/runner'

if on_macruby?
class TestNSObjectExtensions < MiniTest::Unit::TestCase
  # keeping this test just to make sure the version of MacRuby
  # being used is new enough
  def test_inspecting
      url = NSURL.URLWithString('http://marketcircle.com/')
      assert_equal url.description, url.inspect
  end
end
end

