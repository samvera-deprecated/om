require 'spec_helper'

describe "OM::XML::Terminology" do

  before(:each) do
    @test_terminology = OM::XML::Terminology.new

    # @test_name = OM::XML::Term.new("name_")

    @test_name = OM::XML::Term.new(:name)
    @test_child_term = OM::XML::Term.new(:namePart)
    @test_name.add_child @test_child_term
    @test_terminology.add_term(@test_name)

    @builder_with_block = OM::XML::Terminology::Builder.new do |t|
      t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

      t.title_info(:path=>"titleInfo") {
        t.main_title(:path=>"title", :label=>"title") {
          t.main_title_lang(:path=>{:attribute=> "xml:lang"})
        }
        t.language(:path=>{:attribute=>"lang"})
      }
      # t.title(:path=>"titleInfo", :default_content_path=>"title") {
      #   t.@language(:path=>{:attribute=>"lang"})
      # }
      # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
      t.name_ {
        # this is a namepart
        t.namePart(:index_as=>[:searchable, :displayable, :facetable, :sortable], :required=>:true, :type=>:string, :label=>"generic name")
        # affiliations are great
        t.affiliation
        t.displayForm
        t.role(:ref=>[:role])
        t.description
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
        t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
        t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
        t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
        t.person_id(:path=>"namePart", :attributes=>{:type=>:none})
      }
      # lookup :person, :first_name
      t.person(:ref=>:name, :attributes=>{:type=>"personal"})
      t.conference(:ref=>:name, :attributes=>{:type=>"conference"})

      t.role {
        t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
        t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
      }
      t.journal(:path=>'relatedItem', :attributes=>{:type=>"host"}) {
        t.title_info
        t.origin_info(:path=>"originInfo")
        t.issn(:path=>"identifier", :attributes=>{:type=>"issn"})
        t.issue(:ref=>[:issue])
      }
      t.issue(:path=>"part") {
        t.volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
        t.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
        # t.start_page(:path=>"pages", :attributes=>{:type=>"start"})
        # t.end_page(:path=>"pages", :attributes=>{:type=>"end"})
        t.publication_date(:path=>"date")
        t.pages(:path=>"extent", :attributes=>{:unit=>"pages"}) {
          t.start
          t.end
        }
        t.start_page(:proxy=>[:pages, :start])
        t.end_page(:proxy=>[:pages, :end])
      }
      t.title(:proxy=>[:title_info, :main_title])
    end

    @test_full_terminology = @builder_with_block.build

    @namespaceless_terminology = OM::XML::Terminology::Builder.new do |t|
      t.root(:path=>"note", :xmlns=> nil )
      t.to
      t.from
      t.heading
      t.body
    end
    @namespaceless_terminology = @namespaceless_terminology.build

    class NamespacelessTest
      include OM::XML::Document
    end
    NamespacelessTest.terminology = @namespaceless_terminology
    @namespaceless_doc = NamespacelessTest.from_xml(fixture("no_namespace.xml") )
  end

  describe "namespaceless terminologies" do
    it "should generate xpath queries without namespaces" do
      expect(@namespaceless_terminology.xpath_for(:to)).to eq "//to"
      expect(@namespaceless_terminology.xpath_for(:note, :from)).to eq "//note/from"
    end

    it "should work with xml documents that have no namespaces" do
      expect(@namespaceless_doc.from.first).to eq "Jani"
      expect(@namespaceless_doc.to).to eq ["Tove"]
    end
  end

  describe "basics" do

    it "constructs xpath queries for finding properties" do
      expect(@test_full_terminology.retrieve_term(:name).xpath).to eq '//oxns:name'
      expect(@test_full_terminology.retrieve_term(:name).xpath_relative).to eq 'oxns:name'

      expect(@test_full_terminology.retrieve_term(:person).xpath).to eq '//oxns:name[@type="personal"]'
      expect(@test_full_terminology.retrieve_term(:person).xpath_relative).to eq 'oxns:name[@type="personal"]'
      expect(@test_full_terminology.retrieve_term(:person, :person_id).xpath_relative).to eq 'oxns:namePart[not(@type)]'
    end

    it "should expand proxy and get sub terms" do
      expect(@test_full_terminology.retrieve_node(:title, :main_title_lang).xpath).to eq '//oxns:titleInfo/oxns:title/@xml:lang'
      ### retrieve_term() will not cross proxies
      expect(@test_full_terminology.retrieve_term(:title_info, :main_title, :main_title_lang).xpath).to eq '//oxns:titleInfo/oxns:title/@xml:lang'
    end

    it "constructs templates for value-driven searches" do
      expect(@test_full_terminology.retrieve_term(:name).xpath_constrained).to eq '//oxns:name[contains(., "#{constraint_value}")]'.gsub('"', '\"')
      expect(@test_full_terminology.retrieve_term(:person).xpath_constrained).to eq '//oxns:name[@type="personal" and contains(., "#{constraint_value}")]'.gsub('"', '\"')

      # Example of how you could use these templates:
      constraint_value = "SAMPLE CONSTRAINT VALUE"
      constrained_query = eval( '"' + @test_full_terminology.retrieve_term(:person).xpath_constrained + '"' )
      expect(constrained_query).to eq '//oxns:name[@type="personal" and contains(., "SAMPLE CONSTRAINT VALUE")]'
    end

    it "constructs xpath queries & templates for nested terms" do
      name_date_term = @test_full_terminology.retrieve_term(:name, :date)
      expect(name_date_term.xpath).to eq '//oxns:name/oxns:namePart[@type="date"]'
      expect(name_date_term.xpath_relative).to eq 'oxns:namePart[@type="date"]'
      expect(name_date_term.xpath_constrained).to eq '//oxns:name/oxns:namePart[@type="date" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
      # name_date_term.xpath_constrained.should == '//oxns:name[contains(oxns:namePart[@type="date"], "#{constraint_value}")]'.gsub('"', '\"')

      person_date_term = @test_full_terminology.retrieve_term(:person, :date)
      expect(person_date_term.xpath).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="date"]'
      expect(person_date_term.xpath_relative).to eq 'oxns:namePart[@type="date"]'
      expect(person_date_term.xpath_constrained).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="date" and contains(., "#{constraint_value}")]'.gsub('"', '\"')
      # person_date_term.xpath_constrained.should == '//oxns:name[@type="personal" and contains(oxns:namePart[@type="date"], "#{constraint_value}")]'.gsub('"', '\"')
    end

    it "supports subelements that are specified using a :ref" do
      role_term = @test_full_terminology.retrieve_term(:name, :role)
      expect(role_term.xpath).to eq '//oxns:name/oxns:role'
      expect(role_term.xpath_relative).to eq 'oxns:role'
      expect(role_term.xpath_constrained).to eq '//oxns:name/oxns:role[contains(., "#{constraint_value}")]'.gsub('"', '\"')
      # role_term.xpath_constrained.should == '//oxns:name[contains(oxns:role/oxns:roleTerm, "#{constraint_value}")]'.gsub('"', '\"')
    end

    describe "treating attributes as properties" do
      it "should build correct xpath" do    
        language_term = @test_full_terminology.retrieve_term(:title_info, :language)
        expect(language_term.xpath).to eq '//oxns:titleInfo/@lang'
        expect(language_term.xpath_relative).to eq '@lang'
        expect(language_term.xpath_constrained).to eq '//oxns:titleInfo/@lang[contains(., "#{constraint_value}")]'.gsub('"', '\"')
      end
    end

    it "should support deep nesting of properties" do
      volume_term = @test_full_terminology.retrieve_term(:journal, :issue, :volume)
      expect(volume_term.xpath).to eq "//oxns:relatedItem[@type=\"host\"]/oxns:part/oxns:detail[@type=\"volume\"]"
      expect(volume_term.xpath_relative).to eq "oxns:detail[@type=\"volume\"]"
      # volume_term.xpath_constrained.should == "//oxns:part[contains(oxns:detail[@type=\\\"volume\\\"], \\\"\#{constraint_value}\\\")]"
      expect(volume_term.xpath_constrained).to eq '//oxns:relatedItem[@type="host"]/oxns:part/oxns:detail[@type="volume" and contains(oxns:number, "#{constraint_value}")]'.gsub('"', '\"')
    end

    it "should not overwrite default property info when adding a variant property" do
      name_term = @test_full_terminology.retrieve_term(:name)
      person_term = @test_full_terminology.retrieve_term(:person)

      expect(name_term).not_to equal(person_term)
      expect(name_term.xpath).not_to equal(person_term.xpath)
      expect(name_term.children).not_to equal(person_term.children)
      expect(name_term.children[:date].xpath_constrained).not_to equal(person_term.children[:date].xpath_constrained)
    end

  end

  describe '#from_xml' do
    it "should let you load mappings from an xml file" do
      skip
      vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
      expect(vocab).to be_instance_of OM::XML::Terminology
      expect(vocab).mappers.to eq({})
    end
  end

  describe '#to_xml' do
    it "should let you serialize mappings to an xml document" do
      skip
      expect(TerminologyTest.to_xml).to eq("")
    end
  end

  describe ".has_term?" do
    it "should return true if the specified term does exist in the terminology" do
      expect(@test_full_terminology.has_term?(:journal,:issue,:end_page)).to be true
    end
    it "should support term_pointers with array indexes in them (ignoring the indexes)" do
      expect(@test_full_terminology.has_term?(:title_info, :main_title)).to be true
      expect(@test_full_terminology.has_term?({:title_info=>"0"}, :main_title)).to be true
    end
    it "should return false if the specified term does not exist in the terminology" do
      expect(@test_full_terminology.has_term?(:name, :date, :nonexistentTerm, :anotherTermName)).to be_falsey
    end
  end

  describe ".retrieve_term" do
    it "should return the mapper identified by the given pointer" do
      term = @test_terminology.retrieve_term(:name, :namePart)
      expect(term).to eq @test_terminology.terms[:name].children[:namePart]
      expect(term).to eq @test_child_term
    end
    it "should build complete terminologies" do
      expect(@test_full_terminology.retrieve_term(:name, :date)).to be_instance_of OM::XML::Term
      expect(@test_full_terminology.retrieve_term(:name, :date).path).to eq 'namePart'
      expect(@test_full_terminology.retrieve_term(:name, :date).attributes).to eq({:type=>"date"})
      expect(@test_full_terminology.retrieve_term(:name, :affiliation).path).to eq('affiliation')
      expect(@test_full_terminology.retrieve_term(:name, :date).xpath).to eq('//oxns:name/oxns:namePart[@type="date"]')
    end
    it "should support looking up variant Terms" do
      expect(@test_full_terminology.retrieve_term(:person).path).to eq('name')
      expect(@test_full_terminology.retrieve_term(:person).attributes).to eq({:type=>"personal"})
      expect(@test_full_terminology.retrieve_term(:person, :affiliation).path).to eq('affiliation') 
      expect(@test_full_terminology.retrieve_term(:person, :date).xpath).to eq('//oxns:name[@type="personal"]/oxns:namePart[@type="date"]')
    end
    it "should support including root terms in pointer" do
      expect(@test_full_terminology.retrieve_term(:mods)).to be_instance_of OM::XML::Term
      expect(@test_full_terminology.retrieve_term(:mods, :name, :date)).to be_instance_of OM::XML::Term
      expect(@test_full_terminology.retrieve_term(:mods, :name, :date).path).to eq 'namePart'
      expect(@test_full_terminology.retrieve_term(:mods, :name, :date).attributes).to eq({:type=>"date"})
      expect(@test_full_terminology.retrieve_term(:mods, :name, :date).xpath).to eq '//oxns:mods/oxns:name/oxns:namePart[@type="date"]'
    end

    it "should raise an informative error if the desired Term doesn't exist" do
      expect(lambda { @test_full_terminology.retrieve_term(:name, :date, :nonexistentTerm, :anotherTermName) }).to raise_error(OM::XML::Terminology::BadPointerError, "You attempted to retrieve a Term using this pointer: [:name, :date, :nonexistentTerm, :anotherTermName] but no Term exists at that location. Everything is fine until \":nonexistentTerm\", which doesn't exist.")
    end
  end

  describe ".term_xpath" do
    it "should insert calls to xpath array lookup into parent xpaths if parents argument is provided" do
      skip
      # conference_mapper = TerminologyTest.retrieve_mapper(:conference)
      # role_mapper =  TerminologyTest.retrieve_mapper(:conference, :role)
      # text_mapper = TerminologyTest.retrieve_mapper(:conference, :role, :text)
      expect(TerminologyTest.term_xpath({:conference=>0}, {:role=>1}, :text )).to eq '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
      # OM::XML::TermXpathGenerator.expects(:generate_absolute_xpath).with({conference_mapper=>0}, {role_mapper=>1}, text_mapper)
    end
  end

  describe ".xpath_for" do

    it "should retrieve the generated xpath query to match your desires" do
      expect(@test_full_terminology.xpath_for(:person)).to eq '//oxns:name[@type="personal"]'

      expect(@test_full_terminology.xpath_for(:person, "Beethoven, Ludwig van")).to eq '//oxns:name[@type="personal" and contains(., "Beethoven, Ludwig van")]'

      expect(@test_full_terminology.xpath_for(:person, :date)).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="date"]'

      expect(@test_full_terminology.xpath_for(:person, :date, "2010")).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="date" and contains(., "2010")]'

      expect(@test_full_terminology.xpath_for(:person, :person_id)).to eq '//oxns:name[@type="personal"]/oxns:namePart[not(@type)]'

    end

    it "should support including root terms in term pointer" do
      expect(@test_full_terminology.xpath_for(:mods, :person)).to eq '//oxns:mods/oxns:name[@type="personal"]'
      expect(@test_full_terminology.xpath_for(:mods, :person, "Beethoven, Ludwig van")).to eq '//oxns:mods/oxns:name[@type="personal" and contains(., "Beethoven, Ludwig van")]'
    end

    it "should support queries with complex constraints" do
      skip
      expect(@test_full_terminology.xpath_for(:person, {:date=>"2010"})).to eq '//oxns:name[@type="personal" and contains(oxns:namePart[@type="date"], "2010")]'
    end

    it "should support queries with multiple complex constraints" do
      skip
      expect(@test_full_terminology.xpath_for(:person, {:role=>"donor", :last_name=>"Rockefeller"})).to eq '//oxns:name[@type="personal" and contains(oxns:role/oxns:roleTerm, "donor") and contains(oxns:namePart[@type="family"], "Rockefeller")]'
    end

    it "should parrot any strings back to you (in case you already have an xpath query)" do
      expect(@test_full_terminology.xpath_for('//oxns:name[@type="personal"]/oxns:namePart[@type="date"]')).to eq '//oxns:name[@type="personal"]/oxns:namePart[@type="date"]'
    end

    it "should traverse named term proxies transparently" do
      proxied_xpath = @test_full_terminology.xpath_for(:journal, :issue, :pages, :start)
      expect(@test_full_terminology.xpath_for( :journal, :issue, :start_page )).to eq proxied_xpath
    end

  end

  describe ".xpath_with_indexes" do
    it "should return the xpath given in the call to #accessor" do
      expect(@test_full_terminology.xpath_with_indexes( :title_info )).to eq('//oxns:titleInfo')
    end
    it "should support xpath queries as argument" do
      expect(@test_full_terminology.xpath_with_indexes('//oxns:name[@type="personal"][1]/oxns:namePart')).to eq '//oxns:name[@type="personal"][1]/oxns:namePart'
    end
    # Note: Ruby array indexes begin from 0.  In xpath queries (which start from 1 instead of 0), this will be translated accordingly.
    it "should prepend the xpath for any parent nodes, inserting calls to xpath array lookup where necessary" do
      expect(@test_full_terminology.xpath_with_indexes( {:conference=>0}, {:role=>1}, :text )).to eq '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
    end
    it "should be idempotent" do
      expect(@test_full_terminology.xpath_with_indexes( *[{:title_info=>2}, :main_title] )).to eq "//oxns:titleInfo[3]/oxns:title"
      expect(@test_full_terminology.xpath_with_indexes( *[{:title_info=>2}, :main_title] )).to eq "//oxns:titleInfo[3]/oxns:title"
      expect(@test_full_terminology.xpath_with_indexes( *[{:title_info=>2}, :main_title] )).to eq "//oxns:titleInfo[3]/oxns:title"
    end
    it "should traverse named term proxies transparently" do
      proxied_xpath = @test_full_terminology.xpath_with_indexes(:journal, :issue, :pages, :start)
      expect(@test_full_terminology.xpath_with_indexes( :journal, :issue, :start_page )).to eq proxied_xpath
    end
  end

  describe "#xml_builder_template" do

    it "should generate a template call for passing into the builder block (assumes 'xml' as the argument for the block)" do
      expect(@test_full_terminology.xml_builder_template(:person,:date)).to eq 'xml.namePart( \'#{builder_new_value}\', \'type\'=>\'date\' )'
      expect(@test_full_terminology.xml_builder_template(:person,:person_id)).to eq 'xml.namePart( \'#{builder_new_value}\' )'
      expect(@test_full_terminology.xml_builder_template(:name,:affiliation)).to eq 'xml.affiliation( \'#{builder_new_value}\' )'
    end

    it "should accept extra options" do
      # Expected marcrelator_role_xml_builder_template.
      # Include both version to handle either ordering of the hash -- a band-aid hack to fix failing test.
      e1 = %q{xml.roleTerm( '#{builder_new_value}', 'type'=>'code', 'authority'=>'marcrelator' )}
      e2 = %q{xml.roleTerm( '#{builder_new_value}', 'authority'=>'marcrelator', 'type'=>'code' )}
      got = @test_full_terminology.xml_builder_template(:role, :code, {:attributes=>{"authority"=>"marcrelator"}} )
      expect([e1, e2]).to include(got)
      got = @test_full_terminology.xml_builder_template(:person, :role, :code, {:attributes=>{"authority"=>"marcrelator"}} )
      expect([e1, e2]).to include(got)
    end

    it "should work with deeply nested properties" do
      expect(@test_full_terminology.xml_builder_template(:issue, :volume)).to eq "xml.detail( \'type\'=>'volume' ) { xml.number( '\#{builder_new_value}' ) }"
      expect(@test_full_terminology.xml_builder_template(:journal, :issue, :level)).to eq "xml.detail( \'type\'=>'number' ) { xml.number( '\#{builder_new_value}' ) }"
      expect(@test_full_terminology.xml_builder_template(:journal, :issue, :volume)).to eq "xml.detail( \'type\'=>'volume' ) { xml.number( '\#{builder_new_value}' ) }"
      expect(@test_full_terminology.xml_builder_template(:journal, :issue, :pages, :start)).to eq "xml.start( '\#{builder_new_value}' )"
    end

  end

  describe "#term_generic_name" do
    it "should generate a generic accessor name based on an array of pointers" do
      expect(OM::XML::Terminology.term_generic_name( {:conference=>0}, {:role=>1}, :text )).to eq "conference_role_text"
      expect(OM::XML::Terminology.term_generic_name( *[{:conference=>0}, {:role=>1}, :text])).to eq "conference_role_text"
    end
  end

  describe "#term_hierarchical_name" do
    it "should generate a specific accessor name based on an array of pointers and indexes" do
      expect(OM::XML::Terminology.term_hierarchical_name( {:conference=>0}, {:role=>1}, :text )).to eq "conference_0_role_1_text"
      expect(OM::XML::Terminology.term_hierarchical_name( *[{:conference=>0}, {:role=>1}, :text] )).to eq "conference_0_role_1_text"
    end
  end

  describe ".term_builders" do
    it "should return a hash terms that have been added to the root of the terminology, indexed by term name" do
      expect(@test_terminology.terms[:name]).to eq @test_name
    end
  end

  describe ".root_terms" do
    it "should return the terms that have been marked root" do
      expect(@test_full_terminology.root_terms.length).to eq 1
      expect(@test_full_terminology.root_terms.first).to eq @test_full_terminology.terms[:mods]
    end
  end

end
