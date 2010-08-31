require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Term::Builder" do
  
  before(:each) do
    @test_builder = OM::XML::Term::Builder.new("term1")
    @test_builder_2 = OM::XML::Term::Builder.new("term2")
  end
  
  describe '#new' do
  end
  
  describe "configuration methods" do
    it "should set the corresponding .settings value return the mapping object" do
      [:path, :index_as, :required, :data_type, :variant_of, :path, :attributes, :default_content_path].each do |method_name|
        @test_builder.send(method_name, "#{method_name.to_s}foo").should == @test_builder
        @test_builder.settings[method_name].should == "#{method_name.to_s}foo"
      end
    end
    it "should be chainable" do
      test_builder = OM::XML::Term::Builder.new("chainableTerm").index_as(:facetable, :searchable, :sortable, :displayable).required(true).data_type(:text)  
      resulting_settings = test_builder.settings
      resulting_settings[:index_as].should == [:facetable, :searchable, :sortable, :displayable]
      resulting_settings[:required].should == true 
      resulting_settings[:data_type].should == :text
    end
  end

  describe "settings" do
    describe "defaults" do
      it "should be set" do
        @test_builder.settings[:required].should == false
        @test_builder.settings[:data_type].should == :string
        @test_builder.settings[:variant_of].should be_nil
        @test_builder.settings[:attributes].should be_nil
        @test_builder.settings[:default_content_path].should be_nil
      end
    end
  end
  
  describe ".add_child" do
    it "should insert the given Term Builder into the current Term Builder's children" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
      @test_builder.ancestors.should include(@test_builder_2)
    end
  end
  
  describe ".children" do
    it "should return a hash of Term Builders that are the children of the current object, indexed by name" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
    end
  end
  
  describe ".build" do
    it "should build a Term with the given settings and generate its xpath values" do
      test_builder = OM::XML::Term::Builder.new("requiredTextFacet").index_as([:facetable, :searchable, :sortable, :displayable]).required(true).data_type(:text)  
      result = test_builder.build
      result.should be_instance_of OM::XML::Term
      result.index_as.should == [:facetable, :searchable, :sortable, :displayable]
      result.required.should == true 
      result.data_type.should == :text
      
      result.xpath.should == OM::XML::TermXpathGenerator.generate_absolute_xpath(result)
      result.xpath_constrained.should == OM::XML::TermXpathGenerator.generate_constrained_xpath(result)
      result.xpath_relative.should == OM::XML::TermXpathGenerator.generate_relative_xpath(result)
    end
    it "should set path to match name if it is empty" do
      @test_builder.settings[:path].should be_nil
      @test_builder.build.path.should == @test_builder.name.to_s
    end
    it "should work recursively, calling .build on any of its children" do
      built_child1 = OM::XML::Term.new("child1")
      built_child2 = OM::XML::Term.new("child2")

      mock1 = mock("Builder1", :build => built_child1 )
      mock2 = mock("Builder2", :build => built_child2 )
      mock1.stubs(:name).returns("child1")
      mock1.stubs(:name).returns("child2")

      @test_builder.children = {:mock1=>mock1, :mock2=>mock2}
      result = @test_builder.build
      result.children[:child1].should == built_child1
      result.children[:child2].should == built_child2
      result.children.length.should == 2
    end
  end

end