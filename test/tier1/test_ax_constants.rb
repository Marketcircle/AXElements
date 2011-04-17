class TestAXConstants < MiniTest::Unit::TestCase
  def test_system_is_the_system_wide_object
    assert_instance_of AX::SystemWide, AX::SYSTEM
  end

  def test_dock_is_an_application
    assert_instance_of AX::Application, AX::DOCK
  end
  def test_dock_is_the_dock_application
    assert_equal 'Dock', AX::DOCK.get_attribute(:title)
  end

  def test_finder_is_an_application
    assert_instance_of AX::Application, AX::FINDER
  end
  def test_finder_is_the_finder_application
    assert_equal 'Finder', AX::FINDER.get_attribute(:title)
  end
end
