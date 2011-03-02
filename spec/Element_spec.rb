require './helper'

describe AX::Element do

  it 'should be able to click' do
    AX::Element.ancestors.should be_include AX::Traits::Clicking
  end

  it 'should be able wait for notifications' do
    AX::Element.ancestors.should be_include AX::Traits::Notifications
  end

  describe '#methods' do
    it 'should contain attributes'
    it 'should contain actions'
  end

  describe '#ref' do
    it 'should be the low level AXUIElementRef'
  end

  describe '#pid' do
    it 'should get the pid for the application to which the element belongs'
  end

  describe '#attributes' do
  end

  describe '#actions' do
  end

  describe '#attribute_writable?' do
  end

  describe '#attribute_writable?' do
  end

  describe '#attribute' do
  end

  describe '#element_attribute' do
  end

  describe '#elements_attribute' do
  end

  describe '#boxed_attribute' do
  end

  describe '#set_attribute_with_value' do
  end

  describe '#perform_action' do
  end

  describe '#method_missing' do
    it 'should do attribute lookups'
    it 'should do child searching'
    it 'should delegate up if lookups and searching cannot be done'
  end

  describe '#inspect' do
  end

  describe '#respond_to?' do
  end

  describe '#description' do
  end

end
