require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "nokogiri"
require "om"

describe "OM::XML::Container" do
  
  before(:all) do
    class ContainerTest
      include OM::XML::Container
    end
  end
  
  before(:each) do
    @container = ContainerTest.from_xml("<foo><bar>1</bar></foo>")
  end
  
  it "should automatically include the other modules" do
    pending
    ContainerTest.included_modules.should include(OM::XML::Accessor)
    ContainerTest.included_modules.should include(OM::XML::Schema)
  end
  
  it "should add .ng_xml accessor" do
    @container.should respond_to(:ng_xml)
    @container.should respond_to(:ng_xml=)    
  end
  
  describe "new" do
    it "should populate ng_xml with an instance of Nokogiri::XML::Document" do
      @container.ng_xml.class.should == Nokogiri::XML::Document
    end
  end
  
  describe "#from_xml" do
    it "should accept a String, parse it and store it in .ng_xml" do
      Nokogiri::XML::Document.expects(:parse).returns("parsed xml")
      container1 = ContainerTest.from_xml("<foo><bar>1</bar></foo>")
      container1.ng_xml.should == "parsed xml"
    end
    it "should accept a File, parse it and store it in .ng_xml" do
      file = fixture(File.join("mods_articles", "hydrangea_article1.xml"))
      Nokogiri::XML::Document.expects(:parse).returns("parsed xml")
      container1 = ContainerTest.from_xml(file)
      container1.ng_xml.should == "parsed xml"
    end
    it "should accept Nokogiri nodes as input and leave them as-is" do
      parsed_xml = Nokogiri::XML::Document.parse("<foo><bar>1</bar></foo>")
      container1 = ContainerTest.from_xml(parsed_xml)
      container1.ng_xml.should == parsed_xml
    end
  end
  
  describe ".to_xml" do
    it  "should call .ng_xml.to_xml" do
      @container.ng_xml.expects(:to_xml).returns("ng xml")
      @container.to_xml.should == "ng xml"
    end
  end
  
end