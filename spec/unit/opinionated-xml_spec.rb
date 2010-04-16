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
                     
      root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"]          
                
                
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
      
      property :role, :path=>[:name_, "role/roleTerm"],
                  :attributes=>[ { "type"=>["text", "code"] } , "authority"]
                  
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
  
  describe "root_property" do
    it "should initialize root_property class attributes without attributes bleeding over to other OX classes" do
      FakeOxMods.root_property_ref.should == :mods
      FakeOxMods.root_config.should == {:ref=>:mods, :path=>"mods", :namespace=>"http://www.loc.gov/mods/v3", :attributes=>["id", "version"]}
      FakeOxMods.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3"}
      
      FakeOtherOx.root_property_ref.should == :other
      FakeOtherOx.root_config.should == {:namespace=>"http://www.foo.com", :path=>"other", :ref=>:other}
    end
  end
  
  describe "property" do
  end
  
  describe "new" do
    it "should be great" do
      @fakemods.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:ns2"=>"http://www.w3.org/1999/xlink", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns:ns3"=>"http://www.loc.gov/mods/v3"}
    end
  end
  
  it "fails gracefully if you try to look up nodes for an undefined property" do
    @fakemods.lookup(:nobody_home).should == []
  end
  
  it "constructs xpath queries for you" do
    
    @fakemods.expects(:xpath).with('//oxns:name[@type="person"]', @fakemods.ox_namespaces)
    @fakemods.lookup(:person)
    
    @fakemods.expects(:xpath).with('//oxns:name[@type="person" and contains(oxns:namePart[@type="date"], "2010") ]', @fakemods.ox_namespaces)
    @fakemods.lookup(:person, :date=>"2010")
    
    @fakemods.expects(:xpath).with('//oxns:name[contains(oxns:role/oxns:roleterm, "donor") and @type="person"]', @fakemods.ox_namespaces)
    @fakemods.lookup(:person, :role=>"donor")
    
  end
  
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
