require 'test/integration/helper'
require 'accessibility/graph'

class TestAccessibilityGraph < MiniTest::Unit::TestCase

  def test_generate
    p = Accessibility::Graph.new(app.main_window).generate_png!
    assert File.exists? p
    assert_match /^PNG image/, `file --brief #{p}`
  end

end
