require 'test/helper'
require 'accessibility'

class TestAccessibilityDebug < MiniTest::Unit::TestCase
  def test_debug_setting
    assert_respond_to Accessibility, :debug?
    assert_respond_to Accessibility, :debug=
  end
end
