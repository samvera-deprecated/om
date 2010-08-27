require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Term::Builder" do
  
  before(:each) do
    @test_builder = OM::XML::Term::Builder.new
    @test_builder_2 = OM::XML::Term::Builder.new
  end
  
  describe '#new' do
  end
  
  describe "configuration methods" do
    it "should set the corresponding .settings value return the mapping object" do
      [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path].each do |method_name|
        @test_mapping.send(method_name, "#{method_name.to_s}foo").should == @test_mapping
        @test_mapping.settings[method_name].should == "#{method_name.to_s}foo"
      end
    end
    it "should be chainable" do
      test_builder = OM::XML::Term::Builder.new.index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  
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
  
  
  describe ".children" do
    it "should return a hash of Term Builders that are the children of the current object, indexed by name" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
    end
  end
  
  describe ".add_child" do
    it "should insert the given Term Builder into the current Term Builder's children" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
      @test_builder.ancestors.should include(@test_builder_2)
    end
  end
  
  describe ".build" do
    it "should build a Term with the given settings" do
      test_builder = OM::XML::Term::Builder.new.index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  

      result = test_builder.build.should be_instance_of OM::XML::Term
      resulting_settings = MappingsTest.mappings[:namePart].settings
      resulting_settings[:index_as].should == [:facetable, :searchable, :sortable, :displayable]
      resulting_settings[:required].should == true 
      resulting_settings[:type].should == :text
    end
    it "should work recursively, calling .build on any of its children" do
      mock1 = mock("Builder", :build)
      mock2 = mock("Builder", :build)
      @test_builder.expects(:children).returns({:mock1=>mock1, :mock2=>mock2})
      @test_builder.build
    end
  end

end