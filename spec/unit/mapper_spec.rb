require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Mapper" do
  
  before(:each) do
    @test_mapper = OM::XML::Mapper.new(:namePart, {}).generate
    @test_raw_mapper = OM::XML::Mapper.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
  end
  
  describe '#new' do
    it "should set default values" do
      @test_mapper.namespace_prefix.should == "oxns"
    end
    it "should set path from mapper name if no path is provided" do
      @test_mapper.path.should == "namePart"
    end
  end
  
  describe '#from_node' do
    it "should create a mapper from a nokogiri node" do
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mapper(:name=>"person", :path=>"name") {
          xml.attribute(:name=>"type", :value=>"personal")
          xml.mapper(:name=>"first_name", :path=>"namePart") {
            xml.attribute(:name=>"type", :value=>"given")
            xml.attribute(:name=>"another_attribute", :value=>"myval")
          }
        }
      end
      # node = Nokogiri::XML::Document.parse( '<mapper name="first_name" path="namePart"><attribute name="type" value="given"/><attribute name="another_attribute" value="myval"/></mapper>' ).root
      node = builder.doc.root
      mapper = OM::XML::Mapper.from_node(node)
      mapper.name.should == :person
      mapper.path.should == "name"
      mapper.attributes.should == {:type=>"personal"}
      mapper.internal_xml.should == node
            
      child = mapper.children[:first_name]

      child.name.should == :first_name
      child.path.should == "namePart"
      child.attributes.should == {:type=>"given", :another_attribute=>"myval"}
      child.internal_xml.should == node.xpath("./mapper").first
    end
  end
  
  describe ".retrieve_mapper" do
    it "should crawl down into mapper children to find the desired mapper" do
      mock_role = mock("mapper", :children =>{:text=>"the target"})
      mock_conference = mock("mapper", :children =>{:role=>mock_role})   
      @test_mapper.expects(:children).returns({:conference=>mock_conference})   
      @test_mapper.retrieve_mapper(:conference, :role, :text).should == "the target"
    end
    it "should return an empty hash if no mapper can be found" do
      @test_mapper.retrieve_mapper(:journal, :issue, :end_page).should == nil
    end
  end
  
  describe 'inner_xml' do
    it "should be a kind of Nokogiri::XML::Node" do
      pending
      @test_mapper.inner_xml.should be_kind_of(Nokogiri::XML::Node)
    end
  end
  
  describe "getters/setters" do
    it "should set the corresponding .settings value and return the current value" do
      [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |method_name|
        @test_mapper.send(method_name.to_s+"=", "#{method_name.to_s}foo").should == "#{method_name.to_s}foo"
        @test_mapper.send(method_name).should == "#{method_name.to_s}foo"        
      end
    end
  end

  describe ".ancestors" do
    it "should return an array of Mappers that are the ancestors of the current object, ordered from the top/root of the hierarchy" do
      @test_raw_mapper.set_parent(@test_mapper)
      @test_raw_mapper.ancestors.should == [@test_mapper]
    end
  end
  describe ".children" do
    it "should return a hash of Mappers that are the children of the current object, indexed by name" do
      @test_raw_mapper.add_child(@test_mapper)
      @test_raw_mapper.children[@test_mapper.name].should == @test_mapper
    end
  end
  describe ".set_parent" do
    it "should insert the mapper into the given parent" do
      @test_mapper.set_parent(@test_raw_mapper)
      @test_mapper.ancestors.should include(@test_raw_mapper)
      @test_raw_mapper.children[@test_mapper.name].should == @test_mapper
    end
  end
  describe ".add_child" do
    it "should insert the given mapper into the current mappers children" do
      @test_raw_mapper.add_child(@test_mapper)
      @test_raw_mapper.children[@test_mapper.name].should == @test_mapper
      @test_mapper.ancestors.should include(@test_raw_mapper)
    end
  end
  
  describe ".generate" do
    it "should set up the Mapper based on the current settings and return the current object" do
      @test_raw_mapper.generate.should == @test_raw_mapper
    end
    it "should populate the xpath values if options are provided" do
      @test_raw_mapper.xpath_relative.should be_nil
      @test_raw_mapper.xpath.should be_nil
      @test_raw_mapper.xpath_constrained.should be_nil
      @test_raw_mapper.generate
      @test_raw_mapper.xpath_relative.should_not be_nil
      @test_raw_mapper.xpath.should_not be_nil
      @test_raw_mapper.xpath_constrained.should_not be_nil
    end
  end
  
  describe ".regenerate" do
    it "should call .generate" do
      @test_mapper.expects(:generate)
      @test_mapper.regenerate
    end
  end
  
  describe "update_xpath_values" do
    it "should return the current object" do
      @test_mapper.update_xpath_values.should == @test_mapper
    end
    it "should regenerate the xpath values" do      
      @test_raw_mapper.xpath_relative.should be_nil
      @test_raw_mapper.xpath.should be_nil
      @test_raw_mapper.xpath_constrained.should be_nil
      
      @test_raw_mapper.update_xpath_values.should == @test_raw_mapper
      
      @test_raw_mapper.xpath_relative.should == 'oxns:detail[@type="volume"]'
      @test_raw_mapper.xpath.should == '//oxns:detail[@type="volume"]'
      @test_raw_mapper.xpath_constrained.should == '//oxns:detail[@type="volume" and contains(oxns:number, "#{constraint_value}")]'
    end
  end
  
end