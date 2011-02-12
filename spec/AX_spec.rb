require './helper'

describe AX do

  describe '.attribute_prefix' do
    it 'should return a regex' do
      AX.attribute_prefix.class.should be Regexp
    end

    it 'should be overrideable' do
      AX.should respond_to :attribute_prefix=

      old_regex = AX.attribute_prefix
      AX.attribute_prefix         = 'a string!'
      AX.attribute_prefix.should == 'a string!'
      AX.attribute_prefix         = old_regex
    end
  end

  # @todo figure out an easy way to do this
  describe '.make_element' do
  end

  describe '.new_const_get' do
    it 'should return a class, even if it does not exist' do
      AX.new_const_get( :Element ).should be AX::Element
      AX.new_const_get( :RazzleDazzle ).should be AX::RazzleDazzle
    end

    it 'should create new classes if they do not exist' do
      AX.new_const_get( :MadeUpName ).should be AX::MadeUpName
    end
  end

  describe '.plural_const_get' do
    it 'should find things that are not pluralized' do
      AX.plural_const_get('Application').should be
      AX.plural_const_get(:'Application').should be
    end

    it 'should find things that are pluralized with an s' do
      AX.plural_const_get('Applications').should be
      AX.plural_const_get(:'Applications').should be
    end

    it 'should return nil if the class does not exist' do
      AX.plural_const_get('NonExistant').should_not be
      AX.plural_const_get(:'NonExistant').should_not be
    end
  end

  describe '.create_ax_class' do
    it 'should return the class constant for the class I wanted' do
      AX.create_ax_class(:HeyHeyHey).should be AX::HeyHeyHey
    end

    it 'should create class and put it in the AX namespace' do
      AX.create_ax_class :AnotherTestClass
      AX.constants.should be_include :AnotherTestClass
    end

    it 'should make new classes a subclass of AX::Element' do
      AX.create_ax_class :RoflScale
      AX::RoflScale.ancestors.should be_include AX::Element
    end
  end

  # @todo need to manipulate the mouse
  describe '.element_under_mouse' do
    it 'should return some kind of AX::Element object' do
      AX.element_under_mouse.should be_is_a AX::Element
    end

    it 'should return return a menubar item when over a menubar'
    it 'should return a close button when over a Mail window close button'
  end

  # @todo I should really have some more tests for this group
  describe '.element_at_position' do
    it 'should return a menubar item for co-ordinates (10,0)' do
      item = AX.element_at_position CGPoint.new(10, 0)
      item.class.should be AX::MenuBarItem
      item.title.should == "Apple"
    end
  end

  describe '.ride_hierarchy_up' do
    it 'should find the application of an element' do
      item = AX::DOCK.list.application_dock_item
      AX.ride_hierarchy_up( item ).title.should == AX::DOCK.title
    end
  end

  describe 'SYSTEM' do
    it 'should be the SystemWide object' do
      AX::SYSTEM.should be_is_a AX::SystemWide
    end
  end

  describe 'DOCK' do
    it 'should be an AX::Application' do
      AX::DOCK.class.should be AX::Application
    end

    it 'should be the dock application' do
      AX::DOCK.title.should == 'Dock'
    end
  end

  describe '.log' do
    it 'should be initialized to be a logger' do
      AX.log.class.should be Logger
    end

    it 'should be writable' do
      current_logger = AX.log
      new_logger     = Logger.new $stdout
      AX.log         = new_logger
      AX.log.should be new_logger
      AX.log         = current_logger
      AX.log.should be current_logger
    end

    it 'should only be logging error and higher by default' do
      AX.log.level.should be Logger::ERROR
    end
  end

end
