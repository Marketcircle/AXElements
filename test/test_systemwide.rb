class TestAXSystemWide < MiniTest::Unit::TestCase

  # important so that it inherits application functionality
  def test_is_subclass_of_application
    assert AX::SystemWide.ancestors.include?(AX::Application)
  end

end
