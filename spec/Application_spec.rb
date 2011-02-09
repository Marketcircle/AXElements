describe AX::Application do


  it 'should have a super class of AX::Element' do
    AX::Application.ancestors.should be_include AX::Element
  end

  it 'should have the ability to post keyboard events' do
    AX::Application.ancestors.should be_include AX::Traits::Typing
  end


  describe '.application_with_bundle_identifier' do
    it 'should launch the app if it is not running' do
      while true
        mails = NSRunningApplication.runningApplicationsWithBundleIdentifier 'com.apple.mail'
        break if mails.empty?
        mails.first.terminate
      end

      AX::Application.application_with_bundle_identifier 'com.apple.mail'
      mails = NSRunningApplication.runningApplicationsWithBundleIdentifier 'com.apple.mail'
      mails.should_not be_empty
    end

    it 'should return an Application object'
  end


  describe '.application_for_pid' do
    it 'should return an Application object'
  end


  describe '#get_focus' do
    it 'should bring an app to the front if it is in the dock'
  end


  describe '#observer' do
    it 'should return an Observer'
  end

  describe '#inspect' do
  end

end
