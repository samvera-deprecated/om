require 'spec_helper'

describe "OM::XML::Document" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class DocumentTest 

      include OM::XML::Document    
      
      # Could add support for multiple root declarations.  
      #  For now, assume that any modsCollections have already been broken up and fed in as individual mods documents
      # root :mods_collection, :path=>"modsCollection", 
      #           :attributes=>[],
      #           :subelements => :mods
      
      set_terminology do |t|
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

        t.title_info(:path=>"titleInfo") {
          t.main_title(:path=>"title", :label=>"title")
          t.language(:path=>{:attribute=>"lang"})
        }                 
        # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
        t.name_ {
          # this is a namepart
          t.namePart(:index_as=>[:searchable, :displayable, :facetable, :sortable], :required=>:true, :type=>:string, :label=>"generic name")
          # affiliations are great
          t.affiliation
          t.displayForm
          t.role(:ref=>[:role])
          t.description
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
          t.last_name(:path=>"namePart", :attributes=>{:type=>"family"})
          t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
          t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
          t.person_id(:path=>"namePart", :attributes=>{:type=>:none})
        }
        # lookup :person, :first_name        
        t.person(:ref=>:name, :attributes=>{:type=>"personal"})

        t.role {
          t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
          t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
        }
        t.journal(:path=>'relatedItem', :attributes=>{:type=>"host"}) {
          t.title_info
          t.origin_info(:path=>"originInfo")
          t.issn(:path=>"identifier", :attributes=>{:type=>"issn"})
          t.issue(:ref=>:issue)
        }
        t.issue(:path=>"part") {
          t.volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
          t.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
          t.start_page(:path=>"pages", :attributes=>{:type=>"start"})
          t.end_page(:path=>"pages", :attributes=>{:type=>"end"})
          # t.start_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start")
          # t.end_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end")
          t.publication_date(:path=>"date")
        }
      end
           
    end
        
  end
  
  before(:each) do
    @fixturemods = DocumentTest.from_xml( fixture( File.join("CBF_MODS", "ARS0025_016.xml") ) )
    article_xml = fixture( File.join("mods_articles", "hydrangea_article1.xml") )
    @mods_article = DocumentTest.from_xml(article_xml)
  end
  
  after(:all) do
    Object.send(:remove_const, :DocumentTest)
  end
  
  it "should automatically include the necessary modules" do
    DocumentTest.included_modules.should include(OM::XML::Container)
    DocumentTest.included_modules.should include(OM::XML::TermValueOperators)
    DocumentTest.included_modules.should include(OM::XML::Validation)
  end
  
  describe ".ox_namespaces" do
    it "should merge terminology namespaces with document namespaces" do
      @fixturemods.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:ns2"=>"http://www.w3.org/1999/xlink", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns:ns3"=>"http://www.loc.gov/mods/v3", "xmlns"=>"http://www.loc.gov/mods/v3"}
    end
  end
  
  
  describe ".find_by_terms_and_value" do
    it "should fail gracefully if you try to look up nodes for an undefined property" do
      skip "better to get an informative error?"
      @fixturemods.find_by_terms_and_value(:nobody_home).should == []
    end
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      @mods_article.find_by_terms_and_value( :person ).length.should == 2
    end

    it "should allow you to search by term pointer" do
      @fixturemods.ng_xml.should_receive(:xpath).with('//oxns:name[@type="personal"]', @fixturemods.ox_namespaces)
      @fixturemods.find_by_terms_and_value(:person)
    end
    it "should allow you to constrain your searches" do
      @fixturemods.ng_xml.should_receive(:xpath).with('//oxns:name[@type="personal" and contains(., "Beethoven, Ludwig van")]', @fixturemods.ox_namespaces)
      @fixturemods.find_by_terms_and_value(:person, "Beethoven, Ludwig van")
    end
    it "should allow you to use complex constraints" do
      @fixturemods.ng_xml.should_receive(:xpath).with('//oxns:name[@type="personal"]/oxns:namePart[@type="date" and contains(., "2010")]', @fixturemods.ox_namespaces)
      @fixturemods.find_by_terms_and_value(:person, :date=>"2010")
      
      @fixturemods.ng_xml.should_receive(:xpath).with('//oxns:name[@type="personal"]/oxns:role[contains(., "donor")]', @fixturemods.ox_namespaces)
      @fixturemods.find_by_terms_and_value(:person, :role=>"donor")
    end
  end
  describe ".find_by_terms" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      @mods_article.find_by_terms( :person ).length.should == 2
      @mods_article.find_by_terms( {:person=>1} ).first.should == @mods_article.ng_xml.xpath('//oxns:name[@type="personal"][2]', "oxns"=>"http://www.loc.gov/mods/v3").first
      @mods_article.find_by_terms( {:person=>1}, :first_name ).class.should == Nokogiri::XML::NodeSet
      @mods_article.find_by_terms( {:person=>1}, :first_name ).first.text.should == "Siddartha"
    end
    it "should find a NodeSet where a terminology attribute has been set to :none" do
      @mods_article.find_by_terms( {:person=>1}, :person_id).first.text.should == "123987"
    end
    it "should support accessors whose relative_xpath is a lookup array instead of an xpath string" do
      # skip "this only impacts scenarios where we want to display & edit"
      DocumentTest.terminology.retrieve_term(:title_info, :language).path.should == {:attribute=>"lang"}
      # @sample.retrieve( :title, 1 ).first.text.should == "Artikkelin otsikko Hydrangea artiklan 1"
      @mods_article.find_by_terms( {:title_info=>1}, :language ).first.text.should == "finnish"
    end
    
    it "should support xpath queries as the pointer" do
      @mods_article.find_by_terms('//oxns:name[@type="personal"][1]/oxns:namePart[1]').first.text.should == "FAMILY NAME"
    end
    
    it "should return nil if the xpath fails to generate" do
      skip "Can't decide if it's better to return nil or raise an error.  Choosing informative errors for now."
      @mods_article.find_by_terms( {:foo=>20}, :bar ).should == nil
    end
    
    it "should support terms that point to attributes instead of nodes" do
      @mods_article.find_by_terms( {:title_info=>1}, :language ).first.text.should == "finnish"
    end

    it "should support xpath queries as the pointer" do
      @mods_article.find_by_terms('//oxns:name[@type="personal"][1]/oxns:namePart[1]').first.text.should == "FAMILY NAME"
    end
  end
  
  describe "node_exists?" do
    it "should return true if any nodes are found" do
      @mods_article.node_exists?( {:person=>1}, :first_name).should be true
    end
    it "should return false if no nodes are found" do
      @mods_article.node_exists?( {:person=>8}, :first_name ).should be false
    end
    it "should support xpath queries" do
      @mods_article.node_exists?('//oxns:name[@type="personal"][1]/oxns:namePart[1]').should be true
    end
  end
   
end
