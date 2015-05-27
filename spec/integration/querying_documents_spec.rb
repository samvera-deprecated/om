require 'spec_helper'

describe "Rspec tests for QUERYING_DOCUMENTS.md" do

  before(:all) do
    @xml_file = "mods_articles/hydrangea_article1.xml"
    @doc      = OM::Samples::ModsArticle.from_xml(fixture @xml_file) { |conf|
      conf.default_xml.noblanks
    }
    @term = OM::Samples::ModsArticle.terminology
  end

  it "xpath_for()" do
    expect(@term.xpath_for(:name)).to eq '//oxns:name'
    expect(@term.xpath_for(:person)).to eq '//oxns:name[@type="personal"]'
    expect(@term.xpath_for(:organization)).to eq '//oxns:name[@type="corporate"]'
    expect(@term.xpath_for(:person, :first_name)).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="given"]'
    expect(@term.xpath_for(:journal, :issue, :pages, :start)).to eq '//oxns:relatedItem[@type="host"]/oxns:part/oxns:extent[@unit="pages"]/oxns:start'
  end

  it "term_values()" do
    expect(@doc.term_values(:person, :first_name)).to eq ["GIVEN NAMES", "Siddartha"]
    expect(@doc.term_values(:person, :last_name)).to eq ["FAMILY NAME", "Gautama"]
    expect(@doc.term_values(:organization, :namePart)).to eq ['NSF']
    expect(@doc.term_values(:journal, :issue, :pages, :start)).to eq ['195']
    expect(@doc.term_values(:journal, :title_info, :main_title)).to eq ["TITLE OF HOST JOURNAL"]
  end

  it "xpath_for(): relative vs absolute" do
    xp_rel = '//oxns:titleInfo/oxns:title'
    xp_abs = '//oxns:mods/oxns:titleInfo/oxns:title'
    expect(@term.xpath_for(       :title_info, :main_title)).to eq xp_rel
    expect(@term.xpath_for(:mods, :title_info, :main_title)).to eq xp_abs
  end

  it "term_values(): relative vs absolute" do
    exp = [
      "ARTICLE TITLE HYDRANGEA ARTICLE 1",
      "Artikkelin otsikko Hydrangea artiklan 1",
      "TITLE OF HOST JOURNAL",
    ]
    xp_abs = '//oxns:mods/oxns:titleInfo/oxns:title'
    expect(@doc.term_values(       :title_info, :main_title)).to eq exp
    expect(@doc.term_values(:mods, :title_info, :main_title)).to eq exp[0..1]
  end

  it "find_by_terms()" do
    exp_xml_role  = '<role><roleTerm authority="marcrelator" type="text">funder</roleTerm></role>'
    exp_xml_start = '<start>195</start>'
    expect(@doc.find_by_terms(:organization, :role).class).to eq Nokogiri::XML::NodeSet
    expect(@doc.find_by_terms(:organization, :role).to_xml).to be_equivalent_to exp_xml_role
    expect(@doc.find_by_terms(:journal, :issue, :pages, :start).to_xml).to eq exp_xml_start
  end

  it "find_by_terms() error" do
    exp_err = OM::XML::Terminology::BadPointerError
    expect { @doc.find_by_terms :journal, :issue, :BLAH, :start }.to raise_error exp_err
  end

  it "proxies" do
    expect(@term.xpath_for(:title)).to eq '//oxns:titleInfo/oxns:title'
    expect(@term.xpath_for(:journal_title)).to eq'//oxns:relatedItem[@type="host"]/oxns:titleInfo/oxns:title'
  end

end
