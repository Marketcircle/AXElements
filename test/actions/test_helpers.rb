class TestAXElementUnderMouse < MiniTest::Unit::TestCase

  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, AX.element_under_mouse
  end
  # @todo need to manipulate the mouse and put it in some
  #       well known locations and make sure I get the right
  #       element created
end

class TestAXHierarchy < TestAX
  RET = AX.hierarchy( DOCK_APP )
  def test_returns_array_of_elements
    assert_instance_of Array, RET
    assert_kind_of     AX::Element, RET.first
  end
  def test_correctness
    assert_equal 3, RET.size
    assert_instance_of AX::ApplicationDockItem, RET.first
    assert_instance_of AX::List,                RET.second
    assert_instance_of AX::Application,         RET.third
  end
end

class TestAXApplicationForBundleIdentifier < TestAX
  BUNDLE_ID = 'com.apple.systemuiserver'
  def test_makes_an_app
    ret = AX.application_for_bundle_identifier(BUNDLE_ID, 0)
    assert_instance_of AX::Application, ret
  end
  # # @todo this requires launching an app that is not loaded
  # def test_launches_app_if_not_running
  #   # skip 'This test is too invasive, need to find another way or add a test option'
  #   # while true
  #   #   mails = NSRunningApplication.runningApplicationsWithBundleIdentifier 'com.apple.mail'
  #   #   break if mails.empty?
  #   #   mails.first.terminate
  #   # end
  #   # AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #   # mails = NSRunningApplication.runningApplicationsWithBundleIdentifier 'com.apple.mail'
  #   # mails.should_not be_empty
  # end
end
