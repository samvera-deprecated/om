require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology::Builder" do
  
    before(:all) do
      @test_builder = OM::XML::Terminology::Builder.new
      
      @builder_with_block = OM::XML::Terminology::Builder.new do |t|
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

        t.title_info(:path=>"titleInfo") {
          t.main_title(:path=>"title", :label=>"title")
          t.language(:path=>{:attribute=>"lang"})
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
        t.person(:variant_of=>:name_, :attributes=>{:type=>"personal"})

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
    
    describe '#new' do
      it "should return an instance of OM::XML::Terminology::Builder" do
        OM::XML::Terminology::Builder.new.should be_instance_of OM::XML::Terminology::Builder
      end
      it "should process the input block, creating a new Term Builder for each entry and its children" do
        @test_full_terminology.root_terms[:journal].should be_instance_of OM::XML::Term
        @test_full_terminology.root_terms[:journal].path.should == "relatedItem"
        @test_full_terminology.root_terms[:journal].attributes.should == {:type=>"host"}

        @test_full_terminology.root_terms[:journal].children[:issn].should be_instance_of OM::XML::Term
        @test_full_terminology.root_terms[:journal].children[:issn].path.should == "identifier"
        @test_full_terminology.root_terms[:journal].children[:issn].attributes.should == {:type=>"issn"}
      end
      it "should clip the underscore off the end of any Term names" do
        @test_full_terminology.root_terms[:name].should be_instance_of OM::XML::Term
        @test_full_terminology.root_terms[:name].name.should == "name"

        @test_full_terminology.root_terms[:name].children[:date].should be_instance_of OM::XML::Term
        @test_full_terminology.root_terms[:name].children[:date].path.should == "namePart"
        @test_full_terminology.root_terms[:name].children[:date].attributes.should == {:type=>"date"}
      end
      it "should resolve :refs" do
        @test_full_terminology.root_terms[:name].children[:role].children[:text].should be_instance_of OM::XML::Term
        @test_full_terminology.root_terms[:name].children[:role].children[:text].path.should == "roleTerm"
        @test_full_terminology.root_terms[:name].children[:role].children[:text].attributes.should == {:type=>"text"}
      end
    end
    
    describe '#from_xml' do
      it "should let you load mappings from an xml file" do
        pending
        vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
        vocab.should be_instance_of OM::XML::Terminology
        vocab.mappers.should == {}
      end
    end
    
    describe "build" do
      it "should generate the new Terminology, calling .build on its Term builders"
    end
    
    describe '.insert_term' do
      it "should create a new OM::XML::Term::Builder and insert it into the class mappings hash" do
        pending
        
        result = @test_builder.insert_mapper(:name_, :namePart).index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  
        @test_builder.mapper_builders(:name_, :namePart).should == result
        result.should be_instance_of OM::XML::Mapper::Builder
      end
    end
    
    describe ".root" do
      it "should accept options for the root node, such as namespace(s)  and schema and those values should impact the resulting Terminology" do
        root_term_builder = @test_builder.root(:path=>"mods", :xmlns => 'one:two', 'xmlns:foo' => 'bar', :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
        root_term_builder.settings[:is_root_term].should == true
        
        @test_builder.schema.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        @test_builder.namespaces.should == { 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' }
        @test_builder.instance_variable_get(:@root_term_builders).should include(root_term_builder)      
        
        terminology = @test_builder.build
        terminology.schema.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        terminology.namespaces.should == { 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' }
        terminology.retrieve_term(:mods).should be_instance_of OM::XML::Term
        terminology.retrieve_term(:mods).root_term?.should == true
      end
    end
    
end