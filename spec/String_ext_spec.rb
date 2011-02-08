require './helper'

describe String do
  describe '#camelize!' do
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
end
