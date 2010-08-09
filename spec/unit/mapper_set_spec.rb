require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::MapperSet" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class MapperSetTest 
      # p = Property.new("namePart", :required=>:true, :type=>:string)
      # p.index_as = [:facetable, :searchable, :sortable]
      # parent_property << p
      
      # Should lookup always support :attribute as a reserved term that points at attribute values?
      # i.lookup(:title, :attribute=>"lang")
      # i.lookup([:title, :attribute=>"lang"], "eng")
      # ... you could still define mappings to xml nodes called "attribute" using :attribute_
      
      xml_mappings = OM::XML::MapperSet::Builder.new do |m|
        m.mods(:xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd") {
          m.title_info(:path=>"titleInfo") {
            m.main_title(:path=>"title")
            m.language(:path=>{:attribute=>"lang"})
          }          
          # m.title(:path=>"titleInfo", :default_content_path=>"title") {
          #   m.@language(:path=>{:attribute=>"lang"})
          # }
          m.name_ {
            m.namePart(:index_as=>[:facetable, :searchable, :sortable, :displayable], :required=>:true, :type=>:string)
            m.affiliation
            m.displayForm
            m.role!
            m.description
            m.date(:path=>"namePart", :attributes=>{:type=>"date"})
            m.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
            m.given_name(:path=>"namePart", :attributes=>{:type=>"given"})
            m.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
          }            

          m.person(:variant_of=>:name_, :attributes=>{:type=>"personal"})
    
          m.role {
            m.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
            m.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
          }
          m.journal(:path=>'relatedItem', :attributes=>{:type=>"host"}) {
            m.title_info
            m.origin_info(:path=>"originInfo")
            m.issn(:path=>"identifier", :attributes=>{:type=>"issn"})
            m.issue!
          }
          m.issue(:path=>"part") {
            volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
            m.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
            m.start_page(:path=>"pages", :attributes=>{:type=>"start"})
            m.end_page(:path=>"pages", :attributes=>{:type=>"end"})
            # m.start_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start")
            # m.end_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end")
            m.publication_date(:path=>"date")
          }
        }
      end      
    end
    
    describe '#define_mappings' do
      it "should let you load mappings from an xml file" do
        MapperSetTest.define_mappings( fixture("sample_mappings.xml") )
        MapperSetTest.mappings.should == ""
      end
    end
    
    describe '#mapping' do
      it "should create a new OM::XML::Mapping and insert it into the class mappings hash"
        result = MapperSetTest.mapping(:namePart, :name_).index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  
        MapperSetTest.mappings(:namePart).should == result
      end
    end
    

    
    describe "mapper_xpath" do
      it "should insert calls to xpath array lookup into parent xpaths if parents argument is provided" do    
        # conference_mapper = MapperSetTest.retrieve_mapper(:conference)
        # role_mapper =  MapperSetTest.retrieve_mapper(:conference, :role)
        # text_mapper = MapperSetTest.retrieve_mapper(:conference, :role, :text)
        MapperSetTest.mapper_xpath({:conference=>0}, {:role=>1}, :text ).should == '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
        # OM::XML::MapperXpathGenerator.expects(:generate_absolute_xpath).with({conference_mapper=>0}, {role_mapper=>1}, text_mapper)
      end
    end
    
    describe '#to_xml' do
      it "should let you serialize mappings to an xml document" do
        MapperSetTest.to_xml.should == ""
      end
    end
    
end