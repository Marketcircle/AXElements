describe 'Using Mail.app' do

  before do
    @mail = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  end


  describe 'trying to introspect the app' do
    it 'should have a title' do
      @mail.title.should == 'Mail'
    end

    it 'should have children' do
      puts @mail.main_window
    end
  end

end
