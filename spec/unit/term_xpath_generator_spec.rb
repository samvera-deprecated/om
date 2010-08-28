require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::TermXpathGeneratorSpec" do

  before(:all) do
    # builder = OM::XML::Terminology::Builder.new do |m|
    #   m.conference(:attributes=>{:type=>"conference"}) {
    #     m.role {
    #       m.roleTerm(:attributes=>:type=>"text")
    #     }
    #   }
    # end
    # @nested_mappings = builder.build    
  end
  
  before(:each) do
    @test_term = OM::XML::Term.new(:terms_of_address, :path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
    @test_term_with_default_path = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
    @test_role_text = OM::XML::Term.new(:role_text, :path=>"roleTerm", :attributes=>{:type=>"text"})
    
  end
  
  describe "generate_xpath" do
    it "should generate an xpath based on the given mapper and options" do
      OM::XML::TermXpathGenerator.expects(:generate_absolute_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :absolute)
      
      OM::XML::TermXpathGenerator.expects(:generate_relative_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :relative)
      
      OM::XML::TermXpathGenerator.expects(:generate_constrained_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :constrained)
    end
  end
    
  describe "generate_relative_xpath" do
    it "should generate a relative xpath based on the given mapper" do
      OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'oxns:namePart[@type="termsOfAddress"]'
    end
    it "should support mappers without namespaces" do
      @test_term.namespace_prefix = nil
      OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'namePart[@type="termsOfAddress"]'
    end
  end
  
  describe "generate_absolute_xpath" do
    it "should generate an absolute xpath based on the given mapper" do
      OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term).should == '//oxns:namePart[@type="termsOfAddress"]'
    end
    it "should prepend the xpath for any parent nodes" do  
      mock_parent_mapper = mock("Term", :absolute_xpath=>'//oxns:name[@type="conference"]/oxns:role')
      @test_role_text.stubs(:parent).returns(mock_parent_mapper)
      OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_role_text).should == '//oxns:name[@type="conference"]/oxns:role/oxns:roleTerm[@type="text"]'
    end
  end

  describe "generate_constrained_xpath" do
    it "should generate a constrained xpath based on the given mapper" do
      OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term).should == '//oxns:namePart[@type="termsOfAddress" and contains("#{constraint_value}")]' 
    end
  end
  
  it "should support mappers without namespaces" do
    @test_term.namespace_prefix = nil
    OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'namePart[@type="termsOfAddress"]'
    OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term).should == '//namePart[@type="termsOfAddress"]'
    OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term).should == '//namePart[@type="termsOfAddress" and contains("#{constraint_value}")]' 
  end
  
  it "should support mappers with default_content_path" do
    pending "need to implement mapper_set first"
    #@test_term_with_default_path = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
    
    OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term_with_default_path).should == 'oxns:detail[@type="volume"]'
    OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term_with_default_path).should == '//oxns:detail[@type="volume"]'
    OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term_with_default_path).should == "//oxns:detail[contains(oxns:number[@type=\\\"volume\\\"], \\\"\#{constraint_value}\\\")]"
  end
  
end