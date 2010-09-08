require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology::Builder" do
  
    before(:each) do
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

      # @test_full_terminology = @builder_with_block.build
      
    end
    
    describe '#new' do
      it "should return an instance of OM::XML::Terminology::Builder" do
        OM::XML::Terminology::Builder.new.should be_instance_of OM::XML::Terminology::Builder
      end
      it "should process the input block, creating a new Term Builder for each entry and its children" do
        expected_root_terms = [:mods, :title_info, :issue, :person, :name, :journal, :role]
        expected_root_terms.each do |name|
          @builder_with_block.term_builders.should have_key(name)
        end
        @builder_with_block.term_builders.length.should == expected_root_terms.length
        
        @builder_with_block.term_builders[:journal].should be_instance_of OM::XML::Term::Builder
        @builder_with_block.term_builders[:journal].settings[:path].should == "relatedItem"
        @builder_with_block.term_builders[:journal].settings[:attributes].should == {:type=>"host"}

        @builder_with_block.term_builders[:journal].children[:issn].should be_instance_of OM::XML::Term::Builder
        @builder_with_block.term_builders[:journal].children[:issn].settings[:path].should == "identifier"
        @builder_with_block.term_builders[:journal].children[:issn].settings[:attributes].should == {:type=>"issn"}
      end
      it "should clip the underscore off the end of any Term names" do
        @builder_with_block.term_builders[:name].should be_instance_of OM::XML::Term::Builder
        @builder_with_block.term_builders[:name].name.should == :name

        @builder_with_block.term_builders[:name].children[:date].should be_instance_of OM::XML::Term::Builder
        @builder_with_block.term_builders[:name].children[:date].settings[:path].should == "namePart"
        @builder_with_block.term_builders[:name].children[:date].settings[:attributes].should == {:type=>"date"}
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
    
    describe ".retrieve_term_builder" do
      it "should support looking up Term Builders by pointer" do
        expected = @builder_with_block.term_builders[:name].children[:date]
        @builder_with_block.retrieve_term_builder(:name, :date).should == expected
      end
    end
    
    describe "build" do
      it "should generate the new Terminology, calling .build on its Term builders"
      it "should resolve :refs" do
        @builder_with_block.retrieve_term_builder(:name, :role).settings[:ref].should == [:role]
        @builder_with_block.retrieve_term_builder(:role).children[:text].should be_instance_of OM::XML::Term::Builder
        
        built_terminology = @builder_with_block.build
        
        built_terminology.retrieve_term(:name, :role, :text).should be_instance_of OM::XML::Term
        built_terminology.retrieve_term(:name, :role, :text).path.should == "roleTerm"
        built_terminology.retrieve_term(:name, :role, :text).attributes.should == {:type=>"text"}
      end
      it "should set up namespaces" do
        @builder_with_block.build.namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:ns2"=>"http://www.w3.org/1999/xlink", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns:ns3"=>"http://www.loc.gov/mods/v3"}
      end
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
        @test_builder.term_builders[:mods].should == root_term_builder      
        
        terminology = @test_builder.build
        terminology.schema.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        terminology.namespaces.should == { 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' }
        terminology.retrieve_term(:mods).should be_instance_of OM::XML::Term
        terminology.retrieve_term(:mods).root_term?.should == true
      end
    end
    
end