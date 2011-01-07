# -*- coding: utf-8 -*-
describe 'Mail.app' do

  before do
    @mail = AX::Application.application_with_bundle_identifier 'com.apple.mail'
    @mail.get_focus
  end


  describe 'trying to introspect the app' do
    it 'should have a title' do
      @mail.title.should == 'Mail'
    end

    it 'should have children' do
      @mail.children.class.should == Array
      @mail.children.size.should_not == 0 # it must have a menu bar
    end

    it 'should have a menu bar' do
      expect { @mail.menu_bar }.to_not raise_error NoMethodError
    end
  end


  describe 'using the preferences' do
    before do
      mail_menu = @mail.menu_bar.menu_bar_item(title:'Mail')
      mail_menu.press
      mail_menu.menu.menu_item(title:'Preferences…').press
      @window = @mail.focused_window
    end

    it 'should have a toolbar' do
      @window.toolbar.should_not == nil
    end

    it 'should let me switch between tabs' do
      @window.toolbar.button(title:'General').press
      @window.toolbar.button(title:'Accounts').press
      @window.toolbar.button(title:'RSS').press
      @window.toolbar.button(title:'Junk Mail').press
      @window.toolbar.button(title:'Fonts & Colors').press
      @window.toolbar.button(title:'Viewing').press
      @window.toolbar.button(title:'Composing').press
      @window.toolbar.button(title:'Signatures').press
    end

    it 'should let me select the option to automatically CC myself' do
      @window.toolbar.button(title:'Composing').press
      0.upto(15) {
        @window.group.group.check_box(title:'Automatically').press
      }
      @window.group.group.check_box(title:'Automatically').value.should == 0
    end

    after do
      @window.close_button.press
    end
  end


  describe 'writing an email' do
    before do
      @mail.main_window.toolbar.button(title:'New Message').press
      @window = @mail.focused_window
    end

    it 'will let me make a simple email' do
      @window.scroll_areas.each { |area|
        area.text_fields.each { |field|
          if field.title_uielement.value == 'To:'
            field.value = 'mrada@marketcircle.com'
          end
        } if area.text_field
      }

      @window.text_fields.each { |field|
        if field.title_uielement.value == 'Subject:'
          field.get_focus
          @mail.post_kb_event 'a test email'
        end
      }

      @window.scroll_areas.each { |area|
        if area.web_area
          area.web_area.left_click
        end
      }
      @mail.post_kb_event 'email body'

      @window.toolbar.button(title:'Send').press
    end
  end

end
