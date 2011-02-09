require './helper'

describe Array, '#method_missing' do
  it 'should delegate to super if the first element is not an AX::Element' do
    expect { [1,2].title_uielement }.should raise_error NoMethodError
  end

  it 'should map the method for the array if the array contains AX::Element objects' do
    expect { AX::DOCK.list.application_dock_items.role }.should_not raise_exception
    AX::DOCK.list.application_dock_items.role.first.class.should == String
  end

  it 'should not singularize methods that are meant to be plural' do
    # based on the fact that #child does not exist
    expect {
      AX::DOCK.list.application_dock_items.children
    }.should_not raise_error NoMethodError
  end

  it 'should singularize methods that do not exist normally as a plural' do
    expect {
      [:roles, :titles, :parents, :positions, :sizes, :urls].each { |attribute|
        AX::DOCK.list.application_dock_items.send attribute
      }
    }.should_not raise_error NoMethodError
  end
end

describe String, '#camelize!' do
  it 'should take a snake case string and make it camel case' do
    'a_method_name'.camelize!.should == 'AMethodName'
    'method_name'.camelize!.should == 'MethodName'
    'name'.camelize!.should == 'Name'
  end

  it 'should returned unchanged strings if the string is already in camel case' do
    'AMethodName'.camelize!.should == 'AMethodName'
    'MethodName'.camelize!.should == 'MethodName'
    'Name'.camelize!.should == 'Name'
  end
end

describe Symbol, '#predicate?' do
  it "should return true if the symbol ends with a '?'" do
    :test?.predicate?.should == true
  end

  it "should return false if the symbol does not end with a '?'" do
    :test.predicate?.should == false
  end

  it "should return false if a '?' appears anywhere except the end of the symbol" do
    :'tes?t'.predicate?.should == false
    :'te?st'.predicate?.should == false
    :'t?est'.predicate?.should == false
    :'?test'.predicate?.should == false
  end
end
