require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "OpinionatedXml" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class FakeOxMods < Nokogiri::XML::Document
      
      include OX
      extend OX::ClassMethods
      
      
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
    
    class FakeOtherOx < Nokogiri::XML::Document
      
      include OX
      extend OX::ClassMethods
      
      root_property :other, "other", "http://www.foo.com"        
      
    end
        
  end
  
  before(:each) do
    @fakemods = FakeOxMods.parse( fixture( File.join("CBF_MODS", "ARS0025_016.xml") ) )
  end
  
  after(:all) do
    Object.send(:remove_const, :FakeOxMods)
  end
  
  describe "#new" do
    it "should set up namespaces" do
      @fakemods.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:ns2"=>"http://www.w3.org/1999/xlink", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns:ns3"=>"http://www.loc.gov/mods/v3"}
    end
  end
  
  describe "#root_property" do
    it "should initialize root_property class attributes without attributes bleeding over to other OX classes" do
      FakeOxMods.root_property_ref.should == :mods
      FakeOxMods.root_config.should == {:ref=>:mods, :path=>"mods", :namespace=>"http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"}
      FakeOxMods.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3"}
      FakeOxMods.schema_url.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
      
      FakeOtherOx.root_property_ref.should == :other
      FakeOtherOx.root_config.should == {:namespace=>"http://www.foo.com", :path=>"other", :ref=>:other}
    end
  end
  
  describe "#property" do
    
    it "fails gracefully if you try to look up nodes for an undefined property" do
      @fakemods.lookup(:nobody_home).should == []
    end
  
    it "constructs xpath queries for you" do
      # pp FakeOxMods.properties
      FakeOxMods.properties[:name_][:xpath].should == '//oxns:name'                
      FakeOxMods.properties[:person][:xpath].should == '//oxns:name[@type="personal"]'
      
      @fakemods.expects(:xpath).with('//oxns:name[@type="personal"]', @fakemods.ox_namespaces)
      @fakemods.lookup(:person)
    
      FakeOxMods.properties[:person][:xpath_constrained].should == '//oxns:name[@type="personal" and contains(oxns:namePart, "#{constraint_value}")]'
      
      @fakemods.expects(:xpath).with('//oxns:name[@type="person" and contains("#Beethoven, Ludwig van")]', @fakemods.ox_namespaces)
      @fakemods.lookup(:person, "Beethoven, Ludwig van")

      #FakeOxMods.properties[:name_][:convenience_methods][:date][:xpath].should == '//oxns:name[contains(oxns:namePart[@type="date"], "#{constraint_value}")]'      
      FakeOxMods.properties[:person][:convenience_methods][:date][:xpath].should == '//oxns:name[@type="personal" and contains(oxns:namePart[@type="date"], "#{constraint_value}")]'
    
      @fakemods.expects(:xpath).with('//oxns:name[@type="person" and contains(oxns:namePart[@type="date"], "2010") ]', @fakemods.ox_namespaces)
      @fakemods.lookup(:person, :date=>"2010")
          
      FakeOxMods.properties[:name_][:convenience_methods][:role][:xpath].should == '//oxns:name[contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'
      FakeOxMods.properties[:person][:convenience_methods][:role][:xpath].should == '//oxns:name[@type="personal" and contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'
      
      @fakemods.expects(:xpath).with('//oxns:name[contains(oxns:role/oxns:roleTerm, "donor") and @type="personal"]', @fakemods.ox_namespaces)
      @fakemods.lookup(:person, :role=>"donor")    
    end
    
    it "constructs xpath queries for subelements too" do
      FakeOxMods.properties[:person][:convenience_methods][:displayForm][:xpath].should == '//oxns:name[@type="personal"]/oxns:displayForm'
      FakeOxMods.properties[:person][:convenience_methods][:displayForm][:xpath_constrained].should == '//oxns:name[@type="personal" and contains(oxns:displayForm, "#{constraint_value}")]'
      FakeOxMods.properties[:person][:convenience_methods][:role][:xpath_constrained].should == '//oxns:name[@type="personal" and contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'
    end
    
    it "should not overwrite default property info when adding a variant property" do
      FakeOxMods.properties[:name_].should_not equal(FakeOxMods.properties[:person])
      FakeOxMods.properties[:name_][:convenience_methods].should_not equal(FakeOxMods.properties[:person][:convenience_methods])

      FakeOxMods.properties[:name_][:xpath].should_not == FakeOxMods.properties[:person][:xpath]
      FakeOxMods.properties[:name_][:convenience_methods][:date][:xpath].should_not == FakeOxMods.properties[:person][:convenience_methods][:date][:xpath]
    end
  
  end
  
  describe ".lookup"  do
    it "mixes convenience methods into xml nodeSets" do
      people_set = @fakemods.lookup(:person)
      people_set.class.should == Nokogiri::XML::NodeSet
      person1 = people_set.first
      [:date, :family_name, :given_name, :terms_of_address].each {|cmeth| person1.should respond_to(cmeth)}
    
      person1.expects(:xpath).with('namePart[@type="date"]')
      date_set = person1.date
      date_set.class.should == Nokogiri::XML::NodeSet
      date_set.first.class.should == Nokogiri::XML::Element

    end
  
    # This lets you benefit from the handy xpath helpers 
    # without the performance cost of mixing in property-specific convenience methods that you might not be using.
    it "skips mixing in convenience methods if you tell it not to" do
      people_set = @fakemods.lookup(:person, :convenience_methods => false)
      person1 = people_set.first
      [:date, :family_name, :given_name, :terms_of_address].each {|cmeth| person1.should_not respond_to(cmeth)}
    end
  end
  
  describe "#generate_xpath" do
    it "should generate an xpath query from the options in the provided hash and should support generating xpaths with constraint values" do
      opts1 = {:path=>"name", :default_content_path=>"namePart"}
      opts2 = {:path=>"originInfo"}
      FakeOxMods.generate_xpath( opts1 ).should == '//oxns:name'
      FakeOxMods.generate_xpath( opts1, :constraints=>:default ).should == '//oxns:name[contains(oxns:namePart, "#{constraint_value}")]'
      FakeOxMods.generate_xpath( opts2, :constraints=>:default ).should == '//oxns:originInfo[contains("#{constraint_value}")]'

      FakeOxMods.generate_xpath( opts1, :variations=>{:attributes=>{:type=>"personal"}} ).should == '//oxns:name[@type="personal"]'
      FakeOxMods.generate_xpath( opts1, :variations=>{:attributes=>{:type=>"personal"}}, :constraints=>:default ).should == '//oxns:name[@type="personal" and contains(oxns:namePart, "#{constraint_value}")]'
             
      FakeOxMods.generate_xpath( opts1, :constraints=>{:path=>"namePart", :attributes=>{:type=>"date"}} ).should == '//oxns:name[contains(oxns:namePart[@type="date"], "#{constraint_value}")]'
      FakeOxMods.generate_xpath( opts1, :constraints=>{:path=>"namePart", :attributes=>{:type=>"date"}}, :variations=>{:attributes=>{:type=>"personal"}} ).should == '//oxns:name[@type="personal" and contains(oxns:namePart[@type="date"], "#{constraint_value}")]'
      FakeOxMods.generate_xpath(FakeOxMods.properties[:person], :variations=>{:attributes=>{:type=>"personal"}}, :constraints=>{:path=>"role", :default_content_path=>"roleTerm"}, :subelement_of=>":person").should == '//oxns:name[@type="personal" and contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'
      
      FakeOxMods.generate_xpath(opts1,  :variations=>{:attributes=>{:type=>"personal"}, :subelement_path=>"displayForm" } ).should == '//oxns:name[@type="personal"]/oxns:displayForm'
      FakeOxMods.generate_xpath(opts1,  :variations=>{:attributes=>{:type=>"personal"}}, :constraints=>{:path=>"displayForm"} ).should == '//oxns:name[@type="personal" and contains(oxns:displayForm, "#{constraint_value}")]'
    
    end
    
    it "should work with real properties hashes" do
      FakeOxMods.generate_xpath(FakeOxMods.properties[:person], :variations=>FakeOxMods.properties[:person]).should == "//oxns:name[@type=\"personal\"]"
      FakeOxMods.generate_xpath(FakeOxMods.properties[:person], :variations=>FakeOxMods.properties[:person], :constraints=>{:path=>"role", :default_content_path=>"roleTerm"}, :subelement_of=>":person").should == '//oxns:name[@type="personal" and contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'
    end
    
    it "should support custom templates" do
      opts = {:path=>"name", :default_content_path=>"namePart"}
      FakeOxMods.generate_xpath( opts, :template=>'/#{prefix}:sampleNode/#{prefix}:#{path}[contains(#{default_content_path}, \":::constraint_value:::\")]' ).should == '/oxns:sampleNode/oxns:name[contains(namePart, "#{constraint_value}")]'      
    end
  end
  
  describe "#configure_paths" do
    it "should generate a hash with xpath queries for all of the defined properties, their convenience methods and their subelements"
  end
  
  ## Validation Support 
  # Some of these tests fail when you don't have an internet connection because the mods schema includes other xsd schemas by URL reference.
  
  describe "#schema" do
    it "should return an instance of Nokogiri::XML::Schema loaded from the schema url -- fails if no internet connection" do
      FakeOxMods.schema.should be_kind_of Nokogiri::XML::Schema
    end
  end
  
  describe "#validate" do
    it "should validate the provided document against the schema provided in class definition  -- fails if no internet connection" do
      FakeOxMods.schema.expects(:validate).with(@fakemods).returns([])
      FakeOxMods.validate(@fakemods)
    end
  end
  
  describe ".validate" do
    it "should rely on class validate method" do
      FakeOxMods.expects(:validate).with(@fakemods)
      @fakemods.validate
    end
  end
  
  describe "#schema_file" do
    before(:all) do
      FakeOxMods.schema_file = nil
    end
    
    after(:all) do
      FakeOxMods.schema_file = fixture("mods-3-2.xsd")
    end
    
    it "should lazy load the schema file from the @schema_url" do
      FakeOxMods.instance_variable_get(:@schema_file).should be_nil
      FakeOxMods.expects(:file_from_url).with(FakeOxMods.schema_url).returns("fake file").once
      FakeOxMods.schema_file
      FakeOxMods.instance_variable_get(:@schema_file).should == "fake file"
      FakeOxMods.schema_file.should == "fake file"
    end
  end
  
  describe "#file_from_url" do
    it "should retrieve a file from the provided url over HTTP" do
      FakeOxMods.send(:file_from_url, "http://google.com")
    end
    it "should raise an error if the url is invalid" do
      lambda {FakeOxMods.send(:file_from_url, "")}.should raise_error(RuntimeError, "Could not retrieve file from . Error: No such file or directory - ")
      lambda {FakeOxMods.send(:file_from_url, "foo")}.should raise_error(RuntimeError, "Could not retrieve file from foo. Error: No such file or directory - foo")
    end
    it "should raise an error if file retrieval fails" do
      lambda {FakeOxMods.send(:file_from_url, "http://fedora-commons.org/nonexistent_file")}.should raise_error(RuntimeError, "Could not retrieve file from http://fedora-commons.org/nonexistent_file. Error: 404 Not Found")  
    end
  end
   
end
