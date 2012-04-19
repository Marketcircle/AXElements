require 'test/runner'
require 'rspec/expectations/ax_elements'

class TestRSpecMatchers < MiniTest::Unit::TestCase

  def test_defined
    assert TopLevel.method(:have_child)
    assert TopLevel.method(:have_descendent)
    assert TopLevel.method(:have_descendant)
    assert TopLevel.method(:shortly_have_child)
    assert TopLevel.method(:shortly_have_descendent)
    assert TopLevel.method(:shortly_have_descendant)
  end

end
