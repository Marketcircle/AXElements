require './helper'

describe Symbol do
  describe '#predicate?' do
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
end
