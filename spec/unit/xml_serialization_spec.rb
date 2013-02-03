require 'spec_helper'

describe "OM::XML::Terminology.to_xml" do
  before(:all) do
    @terminology = OM::Samples::ModsArticle.terminology
  end
  it "should put terminology details into the xml" do
    expected_xml = "<namespaces>\n  <namespace>\n    <name>oxns</name>\n    <identifier>http://www.loc.gov/mods/v3</identifier>\n  </namespace>\n  <namespace>\n    <name>xmlns:foo</name>\n    <identifier>http://my.custom.namespace</identifier>\n  </namespace>\n  <namespace>\n    <name>xmlns</name>\n    <identifier>http://www.loc.gov/mods/v3</identifier>\n  </namespace>\n</namespaces>"
    xml = @terminology.to_xml
    xml.xpath("/terminology/schema").to_xml.should == "<schema>http://www.loc.gov/standards/mods/v3/mods-3-2.xsd</schema>"    
    xml.xpath("/terminology/namespaces").to_xml.should be_equivalent_to expected_xml
  end
  it "should call .to_xml on all of the terms" do
    options = {}
    doc = Nokogiri::XML::Document.new
    @terminology.terms.values.each {|term| term.should_receive(:to_xml) }
    @terminology.to_xml(options,doc)
  end
end


describe "OM::XML::Term.to_xml" do
  before(:all) do
    @terminology = OM::Samples::ModsArticle.terminology
    @person =  @terminology.retrieve_term(:person)
    @person_first_name =  @terminology.retrieve_term(:person, :first_name)
  end
  it "should return an xml representation of the Term" do
    xml = @person_first_name.to_xml
    xml.xpath("/term").first.attributes["name"].value.should == "first_name"
    xml.xpath("/term/attributes/type").first.text.should == "given"
    xml.xpath("/term/path").first.text.should == "namePart"
    xml.xpath("/term/namespace_prefix").first.text.should == "oxns"
    xml.xpath("/term/children/*").should be_empty
    xml.xpath("/term/xpath/relative").first.text.should == "oxns:namePart[@type=\"given\"]"
    xml.xpath("/term/xpath/absolute").first.text.should == "//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"given\"]"
    xml.xpath("/term/xpath/constrained").first.text.should == "//oxns:name[@type=\\\"personal\\\"]/oxns:namePart[@type=\\\"given\\\" and contains(., \\\"\#{constraint_value}\\\")]"
    xml.xpath("/term/index_as").first.text.should == ""
    xml.xpath("/term/required").first.text.should == "false"
    xml.xpath("/term/data_type").first.text.should == "string"
  end
  it "should capture root term info" do
    xml = @terminology.root_terms.first.to_xml
    xml.xpath("/term/is_root_term").text.should == "true"
    @person_first_name.to_xml.xpath("/term/is_root_term").should be_empty
  end
  it "should allow you to pass in a document to add the term to" do
    doc = Nokogiri::XML::Document.new
    @person_first_name.to_xml({}, doc).should == doc
  end
  it "should include children" do
    children = @person.to_xml.xpath("//term[@name=\"person\"]/children/*")
    children.length.should == 12
    children.each {|child| child.name.should == "term"}
  end
  it "should skip children if :children=>false" do
    @person.to_xml(:children=>false).xpath("children").should be_empty
  end
end
