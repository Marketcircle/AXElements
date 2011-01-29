describe AX::Application do


  it 'should have a super class of AX::Element' do
    AX::Application.ancestors.should be_include AX::Element
  end


  describe '.application_with_bundle_identifier' do
    it 'should launch the app if it is not running'
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


end
