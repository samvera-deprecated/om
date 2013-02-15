require 'spec_helper'

describe "Rspec tests for QUERYING_DOCUMENTS.textile" do

  before(:all) do
    @xml_file = "mods_articles/hydrangea_article1.xml"
    @doc      = OM::Samples::ModsArticle.from_xml(fixture @xml_file) { |conf|
      conf.default_xml.noblanks
    }
    @term = OM::Samples::ModsArticle.terminology
  end

  it "xpath_for()" do
    @term.xpath_for(:name).should == 
      '//oxns:name'
    @term.xpath_for(:person).should == 
      '//oxns:name[@type="personal"]'
    @term.xpath_for(:organization).should == 
      '//oxns:name[@type="corporate"]'
    @term.xpath_for(:person, :first_name).should ==
      '//oxns:name[@type="personal"]/oxns:namePart[@type="given"]'
    @term.xpath_for(:journal, :issue, :pages, :start).should ==
      '//oxns:relatedItem[@type="host"]/oxns:part/oxns:extent[@unit="pages"]/oxns:start'
  end

  it "term_values()" do
    @doc.term_values(:person, :first_name).should == ["GIVEN NAMES", "Siddartha"]
    @doc.term_values(:person, :last_name).should == ["FAMILY NAME", "Gautama"]
    @doc.term_values(:organization, :namePart).should == ['NSF']
    @doc.term_values(:journal, :issue, :pages, :start).should == ['195']
    @doc.term_values(:journal, :title_info, :main_title).should == ["TITLE OF HOST JOURNAL"]
  end

  it "xpath_for(): relative vs absolute" do
    xp_rel = '//oxns:titleInfo/oxns:title'
    xp_abs = '//oxns:mods/oxns:titleInfo/oxns:title'
    @term.xpath_for(       :title_info, :main_title).should == xp_rel
    @term.xpath_for(:mods, :title_info, :main_title).should == xp_abs
  end

  it "term_values(): relative vs absolute" do
    exp = [
      "ARTICLE TITLE HYDRANGEA ARTICLE 1",
      "Artikkelin otsikko Hydrangea artiklan 1",
      "TITLE OF HOST JOURNAL",
    ]
    xp_abs = '//oxns:mods/oxns:titleInfo/oxns:title'
    @doc.term_values(       :title_info, :main_title).should == exp
    @doc.term_values(:mods, :title_info, :main_title).should == exp[0..1]
  end

  it "find_by_terms()" do
    exp_xml_role  = '<role><roleTerm authority="marcrelator" type="text">funder</roleTerm></role>'
    exp_xml_start = '<start>195</start>'
    @doc.find_by_terms(:organization, :role).class.should == Nokogiri::XML::NodeSet
    @doc.find_by_terms(:organization, :role).to_xml.should be_equivalent_to exp_xml_role
    @doc.find_by_terms(:journal, :issue, :pages, :start).to_xml.should == exp_xml_start
  end

  it "find_by_terms() error" do
    exp_err = OM::XML::Terminology::BadPointerError
    expect { @doc.find_by_terms :journal, :issue, :BLAH, :start }.to raise_error exp_err
  end

  it "proxies" do
    @term.xpath_for(:title).should ==
      '//oxns:titleInfo/oxns:title'
    @term.xpath_for(:journal_title)
      '//oxns:relatedItem[@type="host"]/oxns:titleInfo/oxns:title'
  end

end
