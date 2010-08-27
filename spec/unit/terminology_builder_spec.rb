require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology::Builder" do
  
    before(:all) do
      @test_builder = OM::XML::Terminology::Builder.new
    end
    
    describe '#new' do
      it "should process the input block, creating a new Term Builder for each entry" do
        OM::XML::Terminology::Builder.new do |t|
          t.mods(:xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd") {
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
              volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
              t.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
              t.start_page(:path=>"pages", :attributes=>{:type=>"start"})
              t.end_page(:path=>"pages", :attributes=>{:type=>"end"})
              # t.start_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start")
              # t.end_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end")
              t.publication_date(:path=>"date")
            }
          }
        end
      end
      it "should pass arguments to .root through to the Terminology that's being built" 
      it "should return an instance of OM::XML::Terminology::Builder" do
        OM::XML::Terminology::Builder.new.should be_instance_of OM::XML::Terminology::Builder
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
        pending
        @test_vocabulary.root(:xmlns => 'one:two', 'xmlns:foo' => 'bar', :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
        
        @test_vocabulary.schema.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        @test_vocabulary.namespaces.should == { 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' }
        
        v = @test_vocabulary.build
        v.schema.should == "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        v.namespaces.should == { 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' }
      end
    end
    
end