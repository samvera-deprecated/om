require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class FakePVHClass
  include OX::PropertyValuesHelper
end

def helper
  @fake_includer
end

describe "OX::PropertyValuesHelper" do
  
  before(:all) do
    @fake_includer = FakePVHClass.new
  end
    
  describe ".property_values" do

    it "should call .lookup and then build an array of values from the returned nodeset (using default_node, etc as nessesary)" do
      lookup_opts = "insert args here"
      mock_node = mock("node")
      mock_node.expects(:text).returns("sample value").times(3)
      mock_nodeset = [mock_node, mock_node, mock_node]
      helper.expects(:lookup).with(lookup_opts).returns(mock_nodeset)
      
      helper.property_values(lookup_opts).should == ["sample value","sample value","sample value"]
    end
  
  end

  describe ".property_value_append" do
	
  	it "should call templated builder method on the parent node of the first item returned by the corresponding xpath" do
  	  mock_parent_node = mock("parent node")
  	  mock_node = mock("node", :parent=>mock_parent_node)
  	  mock_nodeset = [mock_node]
  	  helper.expects(:lookup).with(:person, :date=>"2010").returns(mock_nodeset)
  	  
  	  helper.expects(:builder_template).with(:person).returns('my template inserts #{new_builder_value}')
  	  
  	  Nokogiri::XML::Builder.expects(:with).with(mock_parent_node).returns(mock_parent_node)
      
	    helper.property_value_append(:person, {:date=>"2010"}, ["my new value", "another new value"])
	  end
  	
  end

  describe ".property_value_set" do
	
  	  it "should wipe out any existing nodes, use the corresponding builder, and insert new node(s) as the replacement" do
  	    pending
        helper.property_value_set(:person, {:date=>"2010"}, 1, "new value")
  	  end

  end
end