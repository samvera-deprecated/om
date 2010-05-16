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

  describe ".property_values_append" do
	
	  # see ../unit/ox_integration_spec.rb
  	
  end

  describe ".property_value_set" do
	
  	  it "should wipe out any existing nodes, use the corresponding builder, and insert new node(s) as the replacement" do
  	    pending
        helper.property_value_set(:person, {:date=>"2010"}, 1, "new value")
  	  end

  end

end