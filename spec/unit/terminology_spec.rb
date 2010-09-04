require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology" do
  
  before(:each) do
    @test_terminology = OM::XML::Terminology.new

    # @test_root_term = OM::XML::Term.new("name_")

    @test_root_term = OM::XML::Term.new(:name)
    @test_child_term = OM::XML::Term.new(:namePart)
    @test_root_term.add_child @test_child_term
    @test_terminology.add_term(@test_root_term)
    @test_terminology.root_term = @test_root_term

    @builder_with_block = OM::XML::Terminology::Builder.new do |t|
      t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

      t.title_info(:path=>"titleInfo") {
        t.main_title(:path=>"title", :label=>"title")
        # t.language(:path=>{:attribute=>"lang"})
      }          
      # t.title(:path=>"titleInfo", :default_content_path=>"title") {
      #   t.@language(:path=>{:attribute=>"lang"})
      # }            
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
        t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
        t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
        t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
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
        t.issue!
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

    @test_full_terminology = @builder_with_block.build

    end
    
    describe '#from_xml' do
      it "should let you load mappings from an xml file" do
        pending
        vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
        vocab.should be_instance_of OM::XML::Terminology
        vocab.mappers.should == {}
      end
    end
    
    describe '#to_xml' do
      it "should let you serialize mappings to an xml document" do
        pending
        TerminologyTest.to_xml.should == ""
      end
    end
    
    describe ".retrieve_term" do
      it "should return the mapper identified by the given pointer" do
        term = @test_terminology.retrieve_term(:name, :namePart)
        term.should == @test_terminology.root_terms[:name].children[:namePart]
        term.should == @test_child_term
      end
      it "should build complete terminologies" do
        @test_full_terminology.retrieve_term(:name, :date).should be_instance_of OM::XML::Term
        @test_full_terminology.retrieve_term(:name, :date).path.should == 'namePart'
        @test_full_terminology.retrieve_term(:name, :date).attributes.should == {:type=>"date"}
        @test_full_terminology.retrieve_term(:name, :affiliation).path.should == 'affiliation'
        @test_full_terminology.retrieve_term(:name, :date).xpath.should == '//oxns:name/oxns:namePart[@type="date"]'          
      end
      it "should support looking up variant Terms" do
        @test_full_terminology.retrieve_term(:person).path.should == 'name'        
        @test_full_terminology.retrieve_term(:person).attributes.should == {:type=>"personal"}        
        @test_full_terminology.retrieve_term(:person, :affiliation).path.should == 'affiliation'
        @test_full_terminology.retrieve_term(:person, :date).xpath.should == '//oxns:name[@type="personal"]/oxns:namePart[@type="date"]'          
      end
      it "should support including root terms in pointer" do
        @test_full_terminology.retrieve_term(:mods).should be_instance_of OM::XML::Term
        @test_full_terminology.retrieve_term(:mods, :name, :date).should be_instance_of OM::XML::Term
        @test_full_terminology.retrieve_term(:mods, :name, :date).path.should == 'namePart'
        @test_full_terminology.retrieve_term(:mods, :name, :date).attributes.should == {:type=>"date"}
        @test_full_terminology.retrieve_term(:mods, :name, :date).xpath.should == '//oxns:mods/oxns:name/oxns:namePart[@type="date"]'          
      end
      
      it "should raise an informative error if the desired Term doesn't exist" do
        lambda { @test_full_terminology.retrieve_term(:name, :date, :nonexistentTerm, :anotherTermName) }.should raise_error(OM::XML::Terminology::BadPointerError, "You attempted to retrieve a Term using this pointer: [:name, :date, :nonexistentTerm, :anotherTermName] but no Term exists at that location. Everything is fine until \":nonexistentTerm\", which doesn't exist.") 
      end
    end
    
    describe ".term_xpath" do
      it "should insert calls to xpath array lookup into parent xpaths if parents argument is provided" do    
        pending
        # conference_mapper = TerminologyTest.retrieve_mapper(:conference)
        # role_mapper =  TerminologyTest.retrieve_mapper(:conference, :role)
        # text_mapper = TerminologyTest.retrieve_mapper(:conference, :role, :text)
        TerminologyTest.term_xpath({:conference=>0}, {:role=>1}, :text ).should == '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
        # OM::XML::TermXpathGenerator.expects(:generate_absolute_xpath).with({conference_mapper=>0}, {role_mapper=>1}, text_mapper)
      end
    end
    
    describe ".root_terms" do
      it "should return a hash terms that have been added to the root of the terminology, indexed by term name" do
        @test_terminology.root_terms[:name].should == @test_root_term
      end 
    end
    
    describe ".root_term" do
      it "should return the root mapper for the vocabulary" do
        @test_terminology.root_term.should == @test_root_term
        # @test_terminology.terms.first.should be_instance_of OM::XML::Term
      end
      it "should be private"
    end
  
end