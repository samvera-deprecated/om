require 'spec_helper'

describe "OM::XML::Container" do

  before(:all) do
    class ContainerTest
      include OM::XML::Container
    end
  end

  subject {
    ContainerTest.from_xml("<foo><bar>1</bar></foo>")
  }

  it "should add .ng_xml accessor" do
    expect(subject).to respond_to(:ng_xml)
    expect(subject).to respond_to(:ng_xml=)
  end

  it "should initialize" do
    expect(ContainerTest.new.ng_xml).to be_a_kind_of Nokogiri::XML::Document
  end

  describe "new" do
    it "should populate ng_xml with an instance of Nokogiri::XML::Document" do
      expect(subject.ng_xml.class).to eq Nokogiri::XML::Document
    end
  end

  describe "#from_xml" do
    it "should accept a String, parse it and store it in .ng_xml" do
      expect(Nokogiri::XML::Document).to receive(:parse).and_return("parsed xml")
      container1 = ContainerTest.from_xml("<foo><bar>1</bar></foo>")
      expect(container1.ng_xml).to eq "parsed xml"
    end
    it "should accept a File, parse it and store it in .ng_xml" do
      file = fixture(File.join("mods_articles", "hydrangea_article1.xml"))
      expect(Nokogiri::XML::Document).to receive(:parse).and_return("parsed xml")
      container1 = ContainerTest.from_xml(file)
      expect(container1.ng_xml).to eq "parsed xml"
    end
    it "should accept Nokogiri nodes as input and leave them as-is" do
      parsed_xml = Nokogiri::XML::Document.parse("<foo><bar>1</bar></foo>")
      container1 = ContainerTest.from_xml(parsed_xml)
      expect(container1.ng_xml).to eq parsed_xml
    end
  end

  describe ".to_xml" do
    it  "should call .ng_xml.to_xml" do
      expect(subject.ng_xml).to receive(:to_xml).and_return("ng xml")
      expect(subject.to_xml).to eq("ng xml")
    end

    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (mocked test)' do
      doc = Nokogiri::XML::Document.parse("<test_xml/>")
      mock_new_node = double("new node")
      expect(doc.root).to receive(:add_child).with(subject.ng_xml.root).and_return(mock_new_node)
      result = subject.to_xml(doc)
    end

    it 'should accept an optional Nokogiri::XML Document as an argument and insert its fields into that (functional test)' do
      doc = Nokogiri::XML::Document.parse("<test_xml/>")
      expect(subject.to_xml(doc)).to eq "<?xml version=\"1.0\"?>\n<test_xml>\n  <foo>\n    <bar>1</bar>\n  </foo>\n</test_xml>\n"
    end

    it 'should add to root of Nokogiri::XML::Documents, but add directly to the elements if a Nokogiri::XML::Node is passed in' do
      mock_new_node = double("new node")
      allow(mock_new_node).to receive(:to_xml).and_return("foo")
      doc = Nokogiri::XML::Document.parse("<test_document/>")
      el = Nokogiri::XML::Node.new("test_element", Nokogiri::XML::Document.new)
      skip "Test not fully implemented"
      expect(doc.root).to receive(:add_child).with(subject.ng_xml.root).and_return(mock_new_node)
      expect(el).to receive(:add_child).with(subject.ng_xml.root).and_return(mock_new_node)
      # expect(subject.to_xml(doc)).to be_equivalent_to
      # expect(subject.to_xml(el )).to be_equivalent_to
    end
  end

end
