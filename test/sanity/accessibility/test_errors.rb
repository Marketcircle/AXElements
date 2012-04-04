require 'test/runner'
require 'accessibility/errors'

class TestAccessibilityErrors < MiniTest::Unit::TestCase

  def test_search_failure_is_kind_of_no_method_error
    assert_includes Accessibility::SearchFailure.ancestors, NoMethodError
  end

end
