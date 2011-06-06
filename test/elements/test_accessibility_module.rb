class TestAccessibilityModule < MiniTest::Unit::TestCase

  def test_application_with_name_with_proper_app
    ret = Accessibility.application_with_name('Dock')
    assert_instance_of AX::Application, ret
    assert_equal       'Dock', ret.title
  end

  def test_application_with_name_with_non_existant_app
    assert_nil Accessibility.application_with_name('App That Does Not Exist')
  end

end
