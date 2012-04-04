require 'test/runner'
require 'accessibility/qualifier'

class TestNSDictionaryExtensions < MiniTest::Unit::TestCase

  def test_ax_pp
    assert_equal '',                        {}.ax_pp
    assert_equal '(title: "Hey, listen!")', {title: 'Hey, listen!'}.ax_pp
    assert_equal '(a: 42, b: [3.14])',      {a: 42, b: [3.14]}.ax_pp
    assert_equal '(c(d: ":("))',            {c: {d:':('} }.ax_pp
  end

end
