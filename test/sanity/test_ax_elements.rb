require 'ax_elements'

class TestDefaults < MiniTest::Unit::TestCase

  def test_dock_constant_is_set
    assert_instance_of AX::Application, AX::DOCK
    assert_equal 'Dock', AX::DOCK.title
  end

end
