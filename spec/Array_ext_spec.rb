require './helper'

describe Array do
  describe '#method_missing' do
    it 'should delegate to super if the first element is not an AX::Element' do
      expect { [1,2].title_uielement }.should raise_error NoMethodError
    end

    it 'should map the method for the array if the array contains AX::Element objects' do
      expect { AX::DOCK.list.application_dock_items.role }.should_not raise_exception
      AX::DOCK.list.application_dock_items.role.first.class.should == String
    end
  end
end
