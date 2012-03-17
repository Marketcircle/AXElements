class TestNSArrayCompat < MiniTest::Unit::TestCase

  def test_second_returns_second
    assert_equal :two, NSArray.arrayWithArray([:one, :two]).second
    assert_nil         NSArray.arrayWithArray([:one]).second
  end

  def test_third_returns_third
    assert_equal :three, NSArray.arrayWithArray([:one, :two, :three]).third
    assert_nil           NSArray.arrayWithArray([:one, :two]).third
  end

end
