require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::TermXpathGeneratorSpec" do

  before(:all) do
    builder = OM::XML::Terminology::Builder.new do |t|
      t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
      t.name_ {
        t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
        t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
      }
      # lookup :person, :first_name
      t.person(:ref=>:name, :attributes=>{:type=>"personal"})
      t.family_name(:proxy=>[:name, :family_name])
    end
    @sample_terminology = builder.build
    @rootless_terminology = OM::XML::Terminology.new
  end

  before(:each) do
    @test_term = OM::XML::Term.new(:terms_of_address, :path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
    @test_term_with_default_path = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
    @test_role_text = OM::XML::Term.new(:role_text, :path=>"roleTerm", :attributes=>{:type=>"text"})
    @test_lang_attribute = OM::XML::Term.new(:language, :path=>{:attribute=>"lang"})
    @test_none_attribute_value = OM::XML::Term.new(:person_id, :path=>"namePart", :attributes=>{:type=>:none})

  end

  it "should support terms that are pointers to attribute values" do
    OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :absolute).should == "//@lang"
    OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :relative).should == "@lang"
    OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :constrained).should == '//@lang[contains(., "#{constraint_value}")]'.gsub('"', '\"')
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
      OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'namePart[@type="termsOfAddress"]'
    end
    it "should support mappers without namespaces" do
      @test_term.namespace_prefix = nil
      OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'namePart[@type="termsOfAddress"]'
    end
    it "should not use a namespace for a path set to text() and should include normalize-space to ignore white space" do
      text_term = OM::XML::Term.new(:title_content, :path=>"text()")
      OM::XML::TermXpathGenerator.generate_relative_xpath(text_term).should == 'text()[normalize-space(.)]'
    end
    it "should set a 'not' predicate if the attribute value is :none" do
       OM::XML::TermXpathGenerator.generate_relative_xpath(@test_none_attribute_value).should == 'namePart[not(@type)]'
    end

  end

  describe "generate_absolute_xpath" do
    it "should generate an absolute xpath based on the given mapper" do
      OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term).should == '//namePart[@type="termsOfAddress"]'
    end
    it "should prepend the xpath for any parent nodes" do
      mock_parent_mapper = mock("Term", :xpath_absolute=>'//name[@type="conference"]/role')
      @test_role_text.stubs(:parent).returns(mock_parent_mapper)
      OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_role_text).should == '//name[@type="conference"]/role/roleTerm[@type="text"]'
    end
  end

  describe "generate_constrained_xpath" do
    it "should generate a constrained xpath based on the given mapper" do
      OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term).should == '//namePart[@type="termsOfAddress" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
    end
  end

  it "should support mappers without namespaces" do
    @test_term.namespace_prefix = nil
    OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term).should == 'namePart[@type="termsOfAddress"]'
    OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term).should == '//namePart[@type="termsOfAddress"]'
    OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term).should == '//namePart[@type="termsOfAddress" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
  end

  describe "generate_xpath_with_indexes" do
    it "should accept multiple constraints" do
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology, :person, {:first_name=>"Tim", :family_name=>"Berners-Lee"} )
      # expect an xpath that looks like this: '//oxns:name[@type="personal" and contains(oxns:namePart[@type="family"], "Berners-Lee") and contains(oxns:namePart[@type="given"], "Tim")]'
      # can't use string comparison because the contains functions can arrive in any order
      generated_xpath.should match( /\/\/oxns:name\[@type=\"personal\".*and contains\(oxns:namePart\[@type=\"given\"\], \"Tim\"\).*\]/ )
      generated_xpath.should match( /\/\/oxns:name\[@type=\"personal\".*and contains\(oxns:namePart\[@type=\"family\"\], \"Berners-Lee\"\).*\]/ )
    end
    it "should support xpath queries as argument" do
      OM::XML::TermXpathGenerator.generate_xpath_with_indexes(@sample_terminology, '//oxns:name[@type="personal"][1]/oxns:namePart').should == '//oxns:name[@type="personal"][1]/oxns:namePart'
    end
    it "should return the xpath of the terminology's root node if term pointer is nil" do
      OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology, nil ).should == @sample_terminology.root_terms.first.xpath
    end
    it "should return / if term pointer is nil and the terminology does not have a root term defined" do
      OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @rootless_terminology, nil ).should == "/"
    end
    it "should destringify term pointers before using them" do
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology, {"person"=>"1"}, "first_name" ).should == '//oxns:name[@type="personal"][2]/oxns:namePart[@type="given"]'
      ### Last argument is a filter, we are passing no filters
      @sample_terminology.xpath_with_indexes(:name, {:family_name=>1},{}).should == '//oxns:name/oxns:namePart[@type="family"][2]'
    end
    it "should warn about indexes on a proxy" do
      Logger.any_instance.expects(:warn).with("You attempted to call an index value of 1 on the term \":family_name\". However \":family_name\" is a proxy so we are ignoring the index. See https://jira.duraspace.org/browse/HYDRA-643")
      @sample_terminology.xpath_with_indexes({:family_name=>1}).should == "//oxns:name/oxns:namePart[@type=\"family\"]"
    end
  end

  it "should support mappers with default_content_path" do
    pending "need to implement mapper_set first"
    #@test_term_with_default_path = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")

    OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term_with_default_path).should == 'oxns:detail[@type="volume"]'
    OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term_with_default_path).should == '//oxns:detail[@type="volume"]'
    OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term_with_default_path).should == '//oxns:detail[contains(oxns:number[@type="volume"], "#{constraint_value}")]'.gsub('"', '\"')
  end

  it "should default to using an inherited namspace prefix" do

    term = @sample_terminology.retrieve_term(:person, :first_name)
    OM::XML::TermXpathGenerator.generate_absolute_xpath(term).should == "//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"given\"]"


  end

end
