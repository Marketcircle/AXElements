class TestAXPrefix < MiniTest::Unit::TestCase
  def test_removes_ax_prefix; prefix_test 'AXButton', 'Button'; end
  def test_removes_combination_prefixes; prefix_test 'MCAXButton', 'Button'; end
  def test_works_with_all_caps; prefix_test 'AXURL', 'URL'; end
  def test_works_with_long_name; prefix_test 'AXIsApplicationRunning', 'IsApplicationRunning'; end
  def test_is_not_greedy; prefix_test 'AXMAX', 'MAX'; end
  def prefix_test before, after
    assert_equal after, before.sub(AX.prefix, '')
  end
end

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
