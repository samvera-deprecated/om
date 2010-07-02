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
  
  it "should add .ng_xml accessor" do
    @container.should respond_to(:ng_xml)
    @container.should respond_to(:ng_xml=)    
  end
  
  describe "new" do
    it "should populate ng_xml with an instance of Nokogiri::XML::Document" do
      @container.ng_xml.class.should == Nokogiri::XML::Document
    end
  end
  
  describe '#xml_template' do
    it "should return an empty xml document" do
      ContainerTest.xml_template.to_xml.should == "<?xml version=\"1.0\"?>\n"
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
    it "should initialize from #xml_template if no xml is provided" do
      ContainerTest.expects(:xml_template).returns("fake template")
      ContainerTest.from_xml.ng_xml.should == "fake template"
    end
  end
  
  describe ".to_xml" do
    it  "should call .ng_xml.to_xml" do
      @container.ng_xml.expects(:to_xml).returns("ng xml")
      @container.to_xml.should == "ng xml"
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_xml/>")
      mock_new_node = mock("new node")
      doc.root.expects(:add_child).with(@container.ng_xml.root).returns(mock_new_node)
      result = @container.to_xml(doc)
    end
    
    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
      doc = Nokogiri::XML::Document.parse("<test_xml/>")
      @container.to_xml(doc).should == "<?xml version=\"1.0\"?>\n<test_xml>\n  <foo>\n    <bar>1</bar>\n  </foo>\n</test_xml>\n"
    end
    
    it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a Nokogiri::XML::Node is passed in' do
      mock_new_node = mock("new node")
      mock_new_node.stubs(:to_xml).returns("foo")
      
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
      doc.root.expects(:add_child).with(@container.ng_xml.root).returns(mock_new_node)
      el.expects(:add_child).with(@container.ng_xml.root).returns(mock_new_node)
      @container.to_xml(doc).should 
      @container.to_xml(el)
    end
  end
  
end