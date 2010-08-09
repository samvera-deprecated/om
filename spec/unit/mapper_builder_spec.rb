require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Mapper::Builder" do
  
  before(:each) do
    @test_mapping = OM::XML::Mapping.new(:namePart)
  end
  
  describe '#new' do
    it "should populate the xpath values if no options are provided" do
      local_mapping = OM::XML::Mapping.new(:namePart)
      local_mapping.xpath_relative.should be_nil
      local_mapping.xpath.should be_nil
      local_mapping.xpath_constrained.should be_nil
    end
    it "should cache the xpath values if options are provided" do
      local_mapping = OM::XML::Mapping.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
      local_mapping.xpath_relative.should_not be_nil
      local_mapping.xpath.should_not be_nil
      local_mapping.xpath_constrained.should_not be_nil
    end
  end
  
  describe 'inner_xml' do
    it "should be a kind of Nokogiri::XML::Node" do
      @test_mapping.inner_xml.should be_kind_of(Nokogiri::XML::Node)
    end
  end
  
  describe "configuration methods"
    it "should set the corresponding .settings value return the mapping object" do
      [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path].each do |method_name|
        @test_mapping.send(method_name, "#{method_name.to_s}foo").should == @test_mapping
        @test_mapping.settings[method_name].should == "#{method_name.to_s}foo"
      end
    end
    it "should be chainable"
      test_builder = OM::XML::Mapper::Builder.new.index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  
      resulting_settings = test_builder.settings
      resulting_settings[:index_as].should == [:facetable, :searchable, :sortable, :displayable]
      resulting_settings[:required].should == true 
      resulting_settings[:type].should == :text
    end
  end

  describe "settings" do
    describe "defaults" do
      it "should be set" do
        @test_mapping.settings[:required].should == false
        @test_mapping.settings[:type].should == :text
        @test_mapping.settings[:variant_of].should be_nil
        @test_mapping.settings[:path].should == ""
        @test_mapping.settings[:attributes].should be_nil
        @test_mapping.settings[:default_content_path].should be_nil
      end
    end
  end
  
  describe "build" do
    it "should build a Mapper with the given settings" do
      test_builder = OM::XML::Mapper::Builder.new.index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  

      result = test_builder.build.should be_instance_of OM::XML::Mapper
      resulting_settings = MappingsTest.mappings[:namePart].settings
      resulting_settings[:index_as].should == [:facetable, :searchable, :sortable, :displayable]
      resulting_settings[:required].should == true 
      resulting_settings[:type].should == :text
    end
  end

end