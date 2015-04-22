require 'spec_helper'

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
    expect(OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :absolute)).to eq "//@lang"
    expect(OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :relative)).to eq "@lang"
    expect(OM::XML::TermXpathGenerator.generate_xpath(@test_lang_attribute, :constrained)).to eq '//@lang[contains(., "#{constraint_value}")]'.gsub('"', '\"')
  end

  describe "generate_xpath" do
    it "should generate an xpath based on the given mapper and options" do
      expect(OM::XML::TermXpathGenerator).to receive(:generate_absolute_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :absolute)

      expect(OM::XML::TermXpathGenerator).to receive(:generate_relative_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :relative)

      expect(OM::XML::TermXpathGenerator).to receive(:generate_constrained_xpath).with(@test_term)
      OM::XML::TermXpathGenerator.generate_xpath(@test_term, :constrained)
    end
  end

  describe "generate_relative_xpath" do
    it "should generate a relative xpath based on the given mapper" do
      expect(OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term)).to eq 'namePart[@type="termsOfAddress"]'
    end
    it "should support mappers without namespaces" do
      @test_term.namespace_prefix = nil
      expect(OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term)).to eq 'namePart[@type="termsOfAddress"]'
    end
    it "should not use a namespace for a path set to text() and should include normalize-space to ignore white space" do
      text_term = OM::XML::Term.new(:title_content, :path=>"text()")
      expect(OM::XML::TermXpathGenerator.generate_relative_xpath(text_term)).to eq 'text()[normalize-space(.)]'
    end
    it "should set a 'not' predicate if the attribute value is :none" do
       expect(OM::XML::TermXpathGenerator.generate_relative_xpath(@test_none_attribute_value)).to eq 'namePart[not(@type)]'
    end

  end

  describe "generate_absolute_xpath" do
    it "should generate an absolute xpath based on the given mapper" do
      expect(OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term)).to eq '//namePart[@type="termsOfAddress"]'
    end
    it "should prepend the xpath for any parent nodes" do
      mock_parent_mapper = double("Term", :xpath_absolute=>'//name[@type="conference"]/role')
      @test_role_text.stub(:parent => mock_parent_mapper)
      expect(OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_role_text)).to eq '//name[@type="conference"]/role/roleTerm[@type="text"]'
    end
  end

  describe "generate_constrained_xpath" do
    it "should generate a constrained xpath based on the given mapper" do
      expect(OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term)).to eq '//namePart[@type="termsOfAddress" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
    end
  end

  it "should support mappers without namespaces" do
    @test_term.namespace_prefix = nil
    expect(OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term)).to eq 'namePart[@type="termsOfAddress"]'
    expect(OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term)).to eq '//namePart[@type="termsOfAddress"]'
    expect(OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term)).to eq '//namePart[@type="termsOfAddress" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
  end

  describe "generate_xpath_with_indexes" do
    it "should accept multiple constraints" do
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology,
                                                    :person, {:first_name=>"Tim", :family_name=>"Berners-Lee"} )
      # expect an xpath that looks like this: '//oxns:name[@type="personal" and contains(oxns:namePart[@type="family"], "Berners-Lee") and contains(oxns:namePart[@type="given"], "Tim")]'
      expect(generated_xpath).to match( /\/\/oxns:name\[@type=\"personal\".*and oxns:namePart\[@type=\"given\"\]\[text\(\)=\"Tim\"\].*\]/ )
      expect(generated_xpath).to match( /\/\/oxns:name\[@type=\"personal\".*and oxns:namePart\[@type=\"family\"\]\[text\(\)=\"Berners-Lee\"\].*\]/ )
    end

    it "should find matching nodes" do
      ng = Nokogiri::XML(fixture( File.join("test_dummy_mods.xml")))
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology,
                                                    :person, {:first_name=>"Tim", :family_name=>"Berners-Lee"} )
      expect(ng.xpath(generated_xpath, 'oxns' => "http://www.loc.gov/mods/v3").to_xml).to be_equivalent_to <<EOF
      <ns3:name type="personal">
          <ns3:namePart type="family">Berners-Lee</ns3:namePart>
          <ns3:namePart type="given">Tim</ns3:namePart>
          <ns3:role>
              <ns3:roleTerm type="text" authority="marcrelator">creator</ns3:roleTerm>
              <ns3:roleTerm type="code" authority="marcrelator">cre</ns3:roleTerm>
          </ns3:role>
      </ns3:name>
EOF
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology,
                                                    :person, {:first_name=>"Tim", :family_name=>"Berners"} )
      expect(ng.xpath(generated_xpath, 'oxns' => "http://www.loc.gov/mods/v3")).to be_empty 
      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology,
                                                    :person, {:first_name=>"Frank", :family_name=>"Berners-Lee"} )
      expect(ng.xpath(generated_xpath, 'oxns' => "http://www.loc.gov/mods/v3")).to be_empty 

      generated_xpath = OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology,
                                                     :person, {:first_name=>"Tim", :family_name=>"Howard"} )
      expect(ng.xpath(generated_xpath, 'oxns' => "http://www.loc.gov/mods/v3")).to be_empty 

    end
    it "should support xpath queries as argument" do
      expect(OM::XML::TermXpathGenerator.generate_xpath_with_indexes(@sample_terminology, '//oxns:name[@type="personal"][1]/oxns:namePart')).to eq '//oxns:name[@type="personal"][1]/oxns:namePart'
    end
    it "should return the xpath of the terminology's root node if term pointer is nil" do
      expect(OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology, nil )).to eq @sample_terminology.root_terms.first.xpath
    end
    it "should return / if term pointer is nil and the terminology does not have a root term defined" do
      expect(OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @rootless_terminology, nil )).to eq "/"
    end
    it "should destringify term pointers before using them" do
      expect(OM::XML::TermXpathGenerator.generate_xpath_with_indexes( @sample_terminology, {"person"=>"1"}, "first_name" )).to eq '//oxns:name[@type="personal"][2]/oxns:namePart[@type="given"]'
      ### Last argument is a filter, we are passing no filters
      expect(@sample_terminology.xpath_with_indexes(:name, {:family_name=>1},{})).to eq '//oxns:name/oxns:namePart[@type="family"][2]'
    end
    it "should warn about indexes on a proxy" do
      expect_any_instance_of(Logger).to receive(:warn).with("You attempted to call an index value of 1 on the term \":family_name\". However \":family_name\" is a proxy so we are ignoring the index. See https://jira.duraspace.org/browse/HYDRA-643")
      expect(@sample_terminology.xpath_with_indexes({:family_name=>1})).to eq "//oxns:name/oxns:namePart[@type=\"family\"]"
    end
  end

  it "should support mappers with default_content_path" do
    skip "need to implement mapper_set first"
    #@test_term_with_default_path = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")

    expect(OM::XML::TermXpathGenerator.generate_relative_xpath(@test_term_with_default_path)).to eq 'oxns:detail[@type="volume"]'
    expect(OM::XML::TermXpathGenerator.generate_absolute_xpath(@test_term_with_default_path)).to eq '//oxns:detail[@type="volume"]'
    expect(OM::XML::TermXpathGenerator.generate_constrained_xpath(@test_term_with_default_path)).to eq '//oxns:detail[contains(oxns:number[@type="volume"], "#{constraint_value}")]'.gsub('"', '\"')
  end

  it "should default to using an inherited namspace prefix" do
    term = @sample_terminology.retrieve_term(:person, :first_name)
    expect(OM::XML::TermXpathGenerator.generate_absolute_xpath(term)).to eq "//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"given\"]"
  end

end
