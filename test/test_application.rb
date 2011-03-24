class TestAXApplication < MiniTest::Unit::TestCase

  def test_is_subclass_of_element
    assert AX::Application.ancestors.include?(AX::Element)
  end

  def test_can_post_keyboard_events
    assert AX::DOCK.respond_to?(:post_kb_event)
  end

  # def test_application_with_bundle_identifier_should_launch_app_if_not_running
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

  def test_inspect_includes_pid
    assert_match /\s@pid=/, AX::DOCK.inspect
  end

end
