require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::PropertyValueOperators" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class PropertiesValueOperatorsTest 
      
      include OM::XML::Container     
      include OM::XML::Accessors
      include OM::XML::Properties
      include OM::XML::PropertyValueOperators 
           
      
      # Could add support for multiple root declarations.  
      #  For now, assume that any modsCollections have already been broken up and fed in as individual mods documents
      # root :mods_collection, :path=>"modsCollection", 
      #           :attributes=>[],
      #           :subelements => :mods
                     
      root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
                
      property :title_info, :path=>"titleInfo", 
                  :convenience_methods => {
                    :main_title => {:path=>"title"},
                    :language => {:path=>"@lang"},                    
                  }
      
      property :name_, :path=>"name", 
                  :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                  :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                  :default_content_path => "namePart",
                  :convenience_methods => {
                    :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                    :family_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                    :first_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                    :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}}
                  }
                  
      property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
      
      property :role, :path=>"role",
                  :parents=>[:name_],
                  :attributes=>[ { "type"=>["text", "code"] } , "authority"],
                  :convenience_methods => {
                    :text => {:path=>"roleTerm", :attributes=>{:type=>"text"}},
                    :code => {:path=>"roleTerm", :attributes=>{:type=>"code"}},                    
                  }
                  
      generate_accessors_from_properties
                  
    end
        
  end
  
  before(:each) do
    @sample = PropertiesValueOperatorsTest.from_xml( fixture( File.join("test_dummy_mods.xml") ) )
  end
  
  after(:all) do
    Object.send(:remove_const, :PropertiesValueOperatorsTest)
  end
  
  describe ".property_values" do

    it "should call .lookup and then build an array of values from the returned nodeset (using default_node, etc as nessesary)" do
      lookup_opts = "insert args here"
      mock_node = mock("node")
      mock_node.expects(:text).returns("sample value").times(3)
      mock_nodeset = [mock_node, mock_node, mock_node]
      @sample.expects(:retrieve).with(*lookup_opts).returns(mock_nodeset)
      
      @sample.property_values(lookup_opts).should == ["sample value","sample value","sample value"]
    end
  
  end
  
  
  describe ".update_properties" do
    before(:each) do
      @article = PropertiesValueOperatorsTest.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end
    it "should update the xml according to the lookups in the given hash" do
      properties_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, [{:person=>1}, :family_name]=>"Andronicus", [{"person"=>"1"},:first_name]=>["Titus"],[{:person=>1},:role]=>["otherrole1","otherrole2"] }
      result = @article.update_properties(properties_update_hash)
      result.should == {"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, "person_1_family_name"=>{"0"=>"Andronicus"},"person_1_first_name"=>{"0"=>"Titus"}, "person_1_role"=>{"0"=>"otherrole1","1"=>"otherrole2"}}
      person_0_affiliation = @article.retrieve({:person=>0}, :affiliation)
      person_0_affiliation[0].text.should == "affiliation1"
      person_0_affiliation[1].text.should == "affiliation2"
      person_0_affiliation[2].text.should == "affiliation3"
      
      person_1_family_names = @article.retrieve({:person=>1}, :family_name)
      person_1_family_names.length.should == 1
      person_1_family_names.first.text.should == "Andronicus"
      
      person_1_first_names = @article.retrieve({:person=>1}, :first_name)
      person_1_first_names.first.text.should == "Titus"
      
      person_1_roles = @article.retrieve({:person=>1}, :role)
      person_1_roles[0].text.should == "otherrole1"
      person_1_roles[1].text.should == "otherrole2"
    end
    it "should call property_value_update if the corresponding node already exists" do
      @article.expects(:property_value_update).with('//oxns:titleInfo/oxns:title', 0, "My New Title")
      @article.update_properties( {[:title_info, :main_title] => "My New Title"} )
    end
    it "should call property_values_append if the corresponding node does not already exist or if the requested index is -1" do
      expected_args = {
        :parent_select => PropertiesValueOperatorsTest.accessor_xpath(*[{:person=>0}]) ,
        :child_index => 0,
        :template => [:person, :role],
        :values => "My New Role"
      }
      @article.expects(:property_values_append).with(expected_args).times(2)
      @article.update_properties( {[{:person=>0}, :role] => {"4"=>"My New Role"}} )
      @article.update_properties( {[{:person=>0}, :role] => {"-1"=>"My New Role"}} )
    end
    it "should call property_value_delete where appropriate"

    it "should destringify the field key/lookup pointer" do
      PropertiesValueOperatorsTest.expects(:accessor_xpath).with( *[{:person=>0}, :role]).times(10).returns("//oxns:name[@type=\"personal\"][1]/oxns:role")
      PropertiesValueOperatorsTest.stubs(:accessor_xpath).with( *[{:person=>0}]).returns("//oxns:name[@type=\"personal\"][1]")
      @article.update_properties( { [{":person"=>"0"}, "role"]=>"the role" } )
      @article.update_properties( { [{"person"=>"0"}, "role"]=>"the role" } )
      @article.update_properties( { [{:person=>0}, :role]=>"the role" } )
    end
    
    ### Examples copied over form nokogiri_datastream_spec
    
    it "should apply submitted hash to corresponding datastream field values" do
      result = @article.update_properties( {[{":person"=>"0"}, "first_name"]=>{"0"=>"Billy", "1"=>"Bob", "2"=>"Joe"} })
      result.should == {"person_0_first_name"=>{"0"=>"Billy", "1"=>"Bob", "2"=>"Joe"}}
      # xpath = ds.class.accessor_xpath(*field_key)
      # result = ds.property_values(xpath)
      @article.property_values({:person=>0}, :first_name).should == ["Billy","Bob","Joe"]
      @article.property_values('//oxns:name[@type="personal"][1]/oxns:namePart[@type="given"]').should == ["Billy","Bob","Joe"]
    end
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
      result = @article.update_properties( { [{":person"=>"0"}, "role"]=>"the role" } )
      result.should == {"person_0_role"=>{"0"=>"the role"}}
      @article.property_values({:person=>0}, :role).first.should == "the role"     
      @article.property_values('//oxns:name[@type="personal"][1]/oxns:role').first.should == "the role"
    end
    it "should do nothing if field key is a string (must be an array or symbol).  Will not accept xpath queries!" do
      xml_before = @article.to_xml
      @article.update_properties( { "fubar"=>"the role" } ).should == {}
      @article.to_xml.should == xml_before
    end
    it "should do nothing if there is no accessor corresponding to the given field key" do
      xml_before = @article.to_xml
      @article.update_properties( { [{"fubar"=>"0"}]=>"the role" } ).should == {}
      @article.to_xml.should == xml_before
    end
    
    ### Examples copied over form metadata_datastream_spec
    
    # it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
    #   # In other words, { "fubar"=>"dork" } should have the same effect as { "fubar"=>{"0"=>"dork"} }
    #   pending "this should be working, but for some reason, the updates don't stick"
    #   result = @test_ds.update_indexed_attributes( { "fubar"=>"dork" } )
    #   result.should == {"fubar"=>{"0"=>"dork"}}
    #   @test_ds.fubar_values.should == ["dork"]
    # end
    # 
    it "should work for text fields" do 
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}
      result = @article.update_properties(att)
      result.should == {"person_0_description"=>{"0"=>"mork","1"=>"york"}}
      @article.property_values({:person=>0},:description).should == ['mork', 'york']
      att= {[{"person"=>"0"},"description"]=>{"-1"=>"dork"}}
      result2 = @article.update_properties(att)
      result2.should == {"person_0_description"=>{"2"=>"dork"}}
      @article.property_values({:person=>0},:description).should == ['mork', 'york', 'dork']
    end
    
    it "should return the new index of any added values" do
      @article.property_values({:title_info=>0},:main_title).should == ["ARTICLE TITLE HYDRANGEA ARTICLE 1", "TITLE OF HOST JOURNAL"]
      result = @article.update_properties [{"title_info"=>"0"},"main_title"]=>{"-1"=>"mork"}
      result.should == {"title_info_0_main_title"=>{"2"=>"mork"}}
    end
    # 
    # it "should return accurate response when multiple values have been added in a single run" do
    #   pending
    #   att= {"swank"=>{"-1"=>"mork", "0"=>"york"}}
    #   @test_ds.update_indexed_attributes(att).should == {"swank"=>{"0"=>"york", "1"=>"mork"}}
    # end
    
    # it "should deal gracefully with adding new values at explicitly declared indexes" do
    #   @article.update_properties([:journal, :title]=>["all", "for", "the"]
    #   att = {"fubar"=>{"3"=>'glory'}}
    #   result = @test_ds.update_indexed_attributes(att)
    #   result.should == {"fubar"=>{"3"=>"glory"}}
    #   @test_ds.fubar_values.should == ["all", "for", "the", "glory"]
    #   
    #   @test_ds.fubar_values = []
    #   result = @test_ds.update_indexed_attributes(att)
    #   result.should == {"fubar"=>{"0"=>"glory"}}
    #   @test_ds.fubar_values.should == ["glory"]
    # end
    # 
    # it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
    #   att= {"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}
    #   @test_ds.update_indexed_attributes(att)
    #   @test_ds.fubar_values.should == ['mork', 'york', 'mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   #puts rexml.root.elements.each {|el| el.to_s}
    #   #puts rexml.root.elements.to_a.inspect
    #   rexml.root.elements.to_a.length.should == 3
    #   @test_ds.update_indexed_attributes({"fubar"=>{"1"=>""}})
    #   @test_ds.fubar_values.should == ['mork', 'mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   rexml.root.elements.to_a.length.should == 2
    #   @test_ds.update_indexed_attributes({"fubar"=>{"0"=>:delete}})
    #   @test_ds.fubar_values.should == ['mangle']
    #   rexml = REXML::Document.new(@test_ds.to_xml)
    #   rexml.root.elements.to_a.length.should == 1
    #   
    #   @test_ds.fubar_values = ["val1", nil, "val2"]
    #   @test_ds.update_indexed_attributes({"fubar"=>{"1"=>""}})
    #   @test_ds.fubar_values.should == ["val1", "val2"]
    # end
    
  end
  
  describe ".property_values_append" do
	
  	it "looks up the parent using :parent_select, uses :child_index to choose the parent node from the result set, uses :template to build the node(s) to be inserted, inserts the :values(s) into the node(s) and adds the node(s) to the parent" do      
	    @sample.property_values_append(
        :parent_select => [:person, {:first_name=>"Tim", :family_name=>"Berners-Lee"}] ,
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
      
	    @sample.property_values_append(
        :parent_select => [:person, {:first_name=>"Tim", :family_name=>"Berners-Lee"}] ,
        :child_index => :first,
        :template => [:person, :affiliation],
        :values => ["my new value", "another new value"] 
      ).to_xml.should == expected_result
      
      @sample.lookup(:person, {:first_name=>"Tim", :family_name=>"Berners-Lee"}).first.to_xml.should == expected_result
    end
    
    it "should accept symbols as arguments for generators/lookups" do
      # this appends a role of "my role" into the third "person" node in the document
      @sample.property_values_append(
        :parent_select => :person ,
        :child_index => 3,
        :template => :role,
        :values => "my role" 
      ).to_xml.should #== expected_result
      @sample.lookup(:person)[3].search("./ns3:role[3]").first.text.should == "my role" 
    end
    
    it "should accept parent_select as an (xpath) string and template as a (template) string" do
      # this uses the provided template to add a node into the first node resulting from the xpath '//oxns:name[@type="personal"]'
      expected_result = "<ns3:name type=\"personal\">\n      <ns3:namePart type=\"family\">Berners-Lee</ns3:namePart>\n      <ns3:namePart type=\"given\">Tim</ns3:namePart>\n      <ns3:role>\n          <ns3:roleTerm type=\"text\" authority=\"marcrelator\">creator</ns3:roleTerm>\n          <ns3:roleTerm type=\"code\" authority=\"marcrelator\">cre</ns3:roleTerm>\n      </ns3:role>\n  <ns3:role type=\"code\" authority=\"marcrelator\"><ns3:roleTerm>creator</ns3:roleTerm></ns3:role></ns3:name>"
      
      @sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role', @sample.ox_namespaces).length.should == 1
      
      @sample.property_values_append(
        :parent_select =>'//oxns:name[@type="personal"]',
        :child_index => 0,
        :template => 'xml.role { xml.roleTerm( \'#{builder_new_value}\', :type=>\'code\', :authority=>\'marcrelator\') }',
        :values => "founder" 
      )

      @sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role', @sample.ox_namespaces).length.should == 2
      @sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role[last()]/oxns:roleTerm', @sample.ox_namespaces).first.text.should == "founder"

      # @sample.lookup(:person).first.to_xml.should == expected_result
    end
	  
	  it "should support more complex mixing & matching" do
	    pending "not working because builder_template is not returning the correct template (returns builder for role instead of roleTerm)"
      @sample.ng_xml.xpath('//oxns:name[@type="personal"][2]/oxns:role[1]/oxns:roleTerm', @sample.ox_namespaces).length.should == 2
	    @sample.property_values_append(
        :parent_select =>'//oxns:name[@type="personal"][2]/oxns:role',
        :child_index => 0,
        :template => [ :person, :role, :text, {:attributes=>{"authority"=>"marcrelator"}} ],
        :values => "foo" 
      )

      @sample.ng_xml.xpath('//oxns:name[@type="personal"][2]/oxns:role[1]/oxns:roleTerm', @sample.ox_namespaces).length.should == 3
      @sample.retrieve({:person=>1},:role)[0].search("./oxns:roleTerm[@type=\"text\" and @authority=\"marcrelator\"]", @sample.ox_namespaces).first.text.should == "foo"
	  end
	  
	  it "should raise exception if no node corresponds to the provided :parent_select and :child_index"
  	
  end
  
  describe ".property_value_update" do

    it "should accept an xpath as :parent_select" do
	    sample_xpath = '//oxns:name[@type="personal"][4]/oxns:role/oxns:roleTerm[@type="text"]'
	    @sample.property_value_update(sample_xpath,1,"artist")
      
      # @sample.property_value_update(      
      #         :parent_select =>sample_xpath,
      #         :child_index => 1,
      #         :value => "donor"
      #       )
      
      @sample.ng_xml.xpath(sample_xpath, @sample.ox_namespaces)[1].text.should == "artist"
    end
    
    it "if :select is provided, should update the first node provided by that xpath statement" do
      sample_xpath = '//oxns:name[@type="personal"][1]/oxns:namePart[@type="given"]'
      @sample.property_value_update(sample_xpath,0,"Timmeh")
      @sample.ng_xml.xpath(sample_xpath, @sample.ox_namespaces).first.text.should == "Timmeh"
    end
    
    it "should replace the existing node if you pass a template and values" do
      pending
      @sample.property_value_update(
        :parent_select =>'//oxns:name[@type="personal"]',
        :child_index => 1,
        :template => [ :person, :role, {:attributes=>{"type"=>"code", "authority"=>"marcrelator"}} ],
        :value => "foo"
      )
      1.should == 2
    end
  end
  
  describe ".property_value_delete" do
    it "should accept an xpath query as :select option" do
      generic_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role'
      specific_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role[oxns:roleTerm="visionary"]'
      select_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role[last()]'
      
      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      @sample.lookup(generic_xpath).length.should == 2
      @sample.lookup(specific_xpath).length.should == 1

      @sample.property_value_delete(
        :select =>select_xpath
      )
      # Check that we're finishing with 1 role
      @sample.lookup(generic_xpath).length.should == 1
      # Check that the specific node we want to delete no longer exists
      @sample.lookup(specific_xpath).length.should == 0
    end 
    it "should accept :parent_select, :parent_index and :child_index options instead of a :select" do
            
      generic_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role/oxns:roleTerm'
      specific_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role[oxns:roleTerm="visionary"]'
      
      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      @sample.lookup(generic_xpath).length.should == 4
      @sample.lookup(specific_xpath).length.should == 1

      # this is attempting to delete the last child (in this case roleTerm) from the 3rd role in the document. 
      @sample.property_value_delete(
        :parent_select => [:person, :role],
        :parent_index => 3,
        :child_index => :last
      )
      
      # Check that we're finishing with 1 role
      @sample.lookup(generic_xpath).length.should == 3
      # Check that the specific node we want to delete no longer exists
      @sample.lookup(specific_xpath).length.should == 1
    end
    it "should work if only :parent_select and :child_index are provided" do
      generic_xpath = '//oxns:name[@type="personal"]/oxns:role'
      # specific_xpath = '//oxns:name[@type="personal"]/oxns:role'
      
      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      @sample.lookup(generic_xpath).length.should == 4
      # @sample.lookup(specific_xpath).length.should == 1

      @sample.property_value_delete(
        :parent_select => [:person, :role],
        :child_index => 3
      )
      # Check that we're finishing with 1 role
      @sample.lookup(generic_xpath).length.should == 3
    end
  end
  
end