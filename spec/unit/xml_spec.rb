require 'spec_helper'

describe "OM::XML::Container" do
  
  before(:all) do
    class XMLTest
      include OM::XML
    end
  end
  
  it "should automatically include the other modules" do
    XMLTest.included_modules.should include(OM::XML::Container)
    XMLTest.included_modules.should include(OM::XML::Validation)
  end
  
  describe "#sanitize_pointer" do
    it "should convert any nested arrays into hashes" do
      XMLTest.sanitize_pointer( [[:person,1],:role] ).should == [{:person=>1},:role]
    end
  end
  
end
