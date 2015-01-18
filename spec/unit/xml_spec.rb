require 'spec_helper'

describe "OM::XML::Container" do
  
  before(:all) do
    class XMLTest
      include OM::XML
    end
  end
  
  it "should automatically include the other modules" do
    expect(XMLTest.included_modules).to include(OM::XML::Container)
    expect(XMLTest.included_modules).to include(OM::XML::Validation)
  end
  
  describe "#sanitize_pointer" do
    it "should convert any nested arrays into hashes" do
      expect(XMLTest.sanitize_pointer( [[:person,1],:role] )).to eq [{:person=>1},:role]
    end
  end
  
end
