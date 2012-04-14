require 'test/runner'
require 'accessibility/errors'

class TestAccessibilityErrors < MiniTest::Unit::TestCase

  def test_exception_subclassing
    assert_equal NoMethodError,                Accessibility::SearchFailure.superclass
    assert_equal Accessibility::SearchFailure, Accessibility::PollingTimeout.superclass
  end

end
