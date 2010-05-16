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
	
  	  it "should " do
  	    pending "in progress..."
  	    @fixturemods.property_value_set('//oxns:name[@type="personal"]',1,"foo")
  	    @fixturemods.property_value_set([ [:person,:role], "donor"], 5, "special donor")
  	  end
      
      it "could support alternative notation" do
        pending "this would be for the sake of consistency with the method signature of property_values_append"
        # @fixturemods.property_value_set(
        #           :node_select =>'//oxns:name[@type="personal"]',
        #           :node_index => 1,
        #           :values => "foo" 
        #         ).to_xml.should == expected_result
      end
  end

end