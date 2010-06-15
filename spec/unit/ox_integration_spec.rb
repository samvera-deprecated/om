require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "OpinionatedXml" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class FakeOxIntegrationMods < Nokogiri::XML::Document
      
      include OX      
      
      # Could add support for multiple root declarations.  
      #  For now, assume that any modsCollections have already been broken up and fed in as individual mods documents
      # root :mods_collection, :path=>"modsCollection", 
      #           :attributes=>[],
      #           :subelements => :mods
                     
      root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
                
                
      property :name_, :path=>"name", 
                  :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                  :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                  :default_content_path => "namePart",
                  :convenience_methods => {
                    :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                    :family_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                    :given_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                    :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}}
                  }
                  
      property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
      
      property :role, :path=>"role",
                  :parents=>[:name_],
                  :attributes=>[ { "type"=>["text", "code"] } , "authority"],
                  :default_content_path => "roleTerm"
                  
                  
    end
        
  end
  
  before(:each) do
    @fixturemods = FakeOxIntegrationMods.parse( fixture( File.join("test_dummy_mods.xml") ) )
  end
  
  after(:all) do
    Object.send(:remove_const, :FakeOxIntegrationMods)
  end
  
  describe ".property_values_append" do
	
  	it "looks up the parent using :parent_select, uses :child_index to choose the parent node from the result set, uses :template to build the node(s) to be inserted, inserts the :values(s) into the node(s) and adds the node(s) to the parent" do      
	    @fixturemods.property_values_append(
        :parent_select => [:person, {:given_name=>"Tim", :family_name=>"Berners-Lee"}] ,
        :child_index => :first,
        :template => [:person, :affiliation],
        :values => ["my new value", "another new value"] 
      )
    end
    
    it "should accept parent_select and template [property_reference, lookup_opts] as argument arrays for generators/lookups" do
      # this appends two affiliation nodes into the first person node whose name is Tim Berners-Lee
      expected_result = '<ns3:name type="personal">
      <ns3:namePart type="family">Berners-Lee</ns3:namePart>
      <ns3:namePart type="given">Tim</ns3:namePart>
      <ns3:role>
          <ns3:roleTerm type="text" authority="marcrelator">creator</ns3:roleTerm>
          <ns3:roleTerm type="code" authority="marcrelator">cre</ns3:roleTerm>
      </ns3:role>
  <ns3:affiliation>my new value</ns3:affiliation><ns3:affiliation>another new value</ns3:affiliation></ns3:name>'
      
	    @fixturemods.property_values_append(
        :parent_select => [:person, {:given_name=>"Tim", :family_name=>"Berners-Lee"}] ,
        :child_index => :first,
        :template => [:person, :affiliation],
        :values => ["my new value", "another new value"] 
      ).to_xml.should == expected_result
      
      @fixturemods.lookup(:person, {:given_name=>"Tim", :family_name=>"Berners-Lee"}).first.to_xml.should == expected_result
    end
    
    it "should accept symbols as arguments for generators/lookups" do
      # this appends a role of "my role" into the third "person" node in the document
      expected_result = "<ns3:name type=\"personal\">\n      <ns3:namePart type=\"family\">Klimt</ns3:namePart>\n      <ns3:namePart type=\"given\">Gustav</ns3:namePart>\n  <ns3:role type=\"text\"><ns3:roleTerm>my role</ns3:roleTerm></ns3:role></ns3:name>"
      
      @fixturemods.property_values_append(
        :parent_select => :person ,
        :child_index => 3,
        :template => :role,
        :values => "my role" 
      ).to_xml.should == expected_result

      @fixturemods.lookup(:person)[3].to_xml.should == expected_result
    end
    
    it "should accept parent_select as an (xpath) string and template as a (template) string" do
      # this uses the provided template to add a node into the first node resulting from the xpath '//oxns:name[@type="personal"]'
      expected_result = "<ns3:name type=\"personal\">\n      <ns3:namePart type=\"family\">Berners-Lee</ns3:namePart>\n      <ns3:namePart type=\"given\">Tim</ns3:namePart>\n      <ns3:role>\n          <ns3:roleTerm type=\"text\" authority=\"marcrelator\">creator</ns3:roleTerm>\n          <ns3:roleTerm type=\"code\" authority=\"marcrelator\">cre</ns3:roleTerm>\n      </ns3:role>\n  <ns3:role type=\"code\" authority=\"marcrelator\"><ns3:roleTerm>creator</ns3:roleTerm></ns3:role></ns3:name>"
      @fixturemods.property_values_append(
        :parent_select =>'//oxns:name[@type="personal"]',
        :child_index => 0,
        :template => 'xml.role( :type=>\'code\', :authority=>\'marcrelator\' ) { xml.roleTerm( \'#{builder_new_value}\' ) }',
        :values => "creator" 
      ).to_xml.should == expected_result

      @fixturemods.lookup(:person).first.to_xml.should == expected_result
    end
	  
	  it "should support more complex mixing & matching" do
	    expected_result = "<ns3:name type=\"personal\">\n      <ns3:namePart type=\"family\">Jobs</ns3:namePart>\n      <ns3:namePart type=\"given\">Steve</ns3:namePart>\n      <ns3:namePart type=\"date\">2004</ns3:namePart>\n      <ns3:role>\n          <ns3:roleTerm type=\"text\" authority=\"marcrelator\">creator</ns3:roleTerm>\n          <ns3:roleTerm type=\"code\" authority=\"marcrelator\">cre</ns3:roleTerm>\n      </ns3:role>\n  <ns3:role type=\"code\" authority=\"marcrelator\"><ns3:roleTerm>foo</ns3:roleTerm></ns3:role></ns3:name>"

	    @fixturemods.property_values_append(
        :parent_select =>'//oxns:name[@type="personal"]',
        :child_index => 1,
        :template => [ :person, :role, {:attributes=>{"type"=>"code", "authority"=>"marcrelator"}} ],
        :values => "foo" 
      ).to_xml.should == expected_result

      @fixturemods.lookup(:person)[1].to_xml.should == expected_result
	  end
	  
	  it "should raise exception if no node corresponds to the provided :parent_select and :child_index"
  	
  end
  
  describe ".property_value_update" do

    it "should accept an xpath as :parent_select" do
	    sample_xpath = '//oxns:name[@type="personal"]/oxns:role/oxns:roleTerm[@type="text"]'
	    @fixturemods.property_value_update(      
        :parent_select =>sample_xpath,
        :child_index => 1,
        :value => "donor"
      )
      @fixturemods.xpath(sample_xpath, @fixturemods.ox_namespaces)[1].text.should == "donor"
    end
    
    it "if :select is provided, should update the first node provided by that xpath statement" do
      sample_xpath = '//oxns:name[@type="personal" and position()=1]/oxns:namePart[@type="given"]'
      @fixturemods.property_value_update(
        :select =>sample_xpath,
        :value => "Timmeh"
      )
      @fixturemods.xpath(sample_xpath, @fixturemods.ox_namespaces).first.text.should == "Timmeh"
    end
    
    it "should replace the existing node if you pass a template and values" do
      pending
      @fixturemods.property_value_update(
        :parent_select =>'//oxns:name[@type="personal"]',
        :child_index => 1,
        :template => [ :person, :role, {:attributes=>{"type"=>"code", "authority"=>"marcrelator"}} ],
        :value => "foo"
      )
      1.should == 2
    end
  end
  
end