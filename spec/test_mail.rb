describe 'Using Mail.app' do
  before do
    @mail = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  end

  describe 'introspecting the element' do
    it 'must have a title' do
      @mail.title
    end

    it 'must have children' do
    end

    it 'must have a menu bar' do
      @mail.menu_bar
    end
  end

  describe 'Writing an email' do
  end

  describe 'Navigating the menu bar' do
  end

  describe 'Navigating the preferences' do
  end
end

