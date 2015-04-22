require 'spec_helper'

describe "OM::XML::Terminology.to_xml" do
  before(:all) do
    @terminology = OM::Samples::ModsArticle.terminology
  end
  it "should put terminology details into the xml" do
    expected_xml = "<namespaces>\n  <namespace>\n    <name>oxns</name>\n    <identifier>http://www.loc.gov/mods/v3</identifier>\n  </namespace>\n  <namespace>\n    <name>xmlns:foo</name>\n    <identifier>http://my.custom.namespace</identifier>\n  </namespace>\n  <namespace>\n    <name>xmlns</name>\n    <identifier>http://www.loc.gov/mods/v3</identifier>\n  </namespace>\n</namespaces>"
    xml = @terminology.to_xml
    expect(xml.xpath("/terminology/schema").to_xml).to eq "<schema>http://www.loc.gov/standards/mods/v3/mods-3-2.xsd</schema>"    
    expect(xml.xpath("/terminology/namespaces").to_xml).to be_equivalent_to expected_xml
  end
  it "should call .to_xml on all of the terms" do
    options = {}
    doc = Nokogiri::XML::Document.new
    @terminology.terms.values.each {|term| expect(term).to receive(:to_xml) }
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
    expect(xml.xpath("/term").first.attributes["name"].value).to eq "first_name"
    expect(xml.xpath("/term/attributes/type").first.text).to eq "given"
    expect(xml.xpath("/term/path").first.text).to eq "namePart"
    expect(xml.xpath("/term/namespace_prefix").first.text).to eq "oxns"
    expect(xml.xpath("/term/children/*")).to be_empty
    expect(xml.xpath("/term/xpath/relative").first.text).to eq "oxns:namePart[@type=\"given\"]"
    expect(xml.xpath("/term/xpath/absolute").first.text).to eq "//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"given\"]"
    expect(xml.xpath("/term/xpath/constrained").first.text).to eq "//oxns:name[@type=\\\"personal\\\"]/oxns:namePart[@type=\\\"given\\\" and contains(., \\\"\#{constraint_value}\\\")]"
    expect(xml.xpath("/term/index_as").first.text).to eq ""
    expect(xml.xpath("/term/required").first.text).to eq "false"
    expect(xml.xpath("/term/data_type").first.text).to eq "string"
  end
  it "should capture root term info" do
    xml = @terminology.root_terms.first.to_xml
    expect(xml.xpath("/term/is_root_term").text).to eq("true")
    expect(@person_first_name.to_xml.xpath("/term/is_root_term")).to be_empty
  end
  it "should allow you to pass in a document to add the term to" do
    doc = Nokogiri::XML::Document.new
    expect(@person_first_name.to_xml({}, doc)).to eq doc
  end
  it "should include children" do
    children = @person.to_xml.xpath("//term[@name=\"person\"]/children/*")
    expect(children.length).to eq(12)
    children.each {|child| expect(child.name).to eq "term"}
  end
  it "should skip children if :children=>false" do
    expect(@person.to_xml(:children=>false).xpath("children")).to be_empty
  end
end
