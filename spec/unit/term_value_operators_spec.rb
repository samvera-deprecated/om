require 'spec_helper'

describe "OM::XML::TermValueOperators" do

  before(:each) do
    @sample = OM::Samples::ModsArticle.from_xml( fixture( File.join("test_dummy_mods.xml") ) )
    @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    @empty_sample = OM::Samples::ModsArticle.from_xml("")
  end

  describe ".term_values" do

    it "should return build an array of values from the nodeset corresponding to the given term" do
      expected_values = ["Berners-Lee", "Jobs", "Wozniak", "Klimt"]
      result = @sample.term_values(:person, :last_name)
      expect(result.length).to eq expected_values.length
      expected_values.each {|v| expect(result).to include(v)}
    end

    it "should look at the index" do
      result = @sample.term_values(:role, {:text => 3})
      expect(result).to eq ['visionary']
    end

    it "should ignore whitespace elements for a term pointing to a text() node for an element that contains children" do
      expect(@article.term_values(:name, :name_content)).to eq ["Describes a person"]
    end

  end


  describe ".update_values" do
    it "should update the xml according to the find_by_terms_and_values in the given hash" do
      terms_attributes = {[{":person"=>"0"}, "affiliation"]=>{'1' => "affiliation1", '2'=> "affiliation2", '3' => "affiliation3"}, [{:person=>1}, :last_name]=>"Andronicus", [{"person"=>"1"},:first_name]=>["Titus"],[{:person=>1},:role]=>["otherrole1","otherrole2"] }
      result = @article.update_values(terms_attributes)
      expect(result).to eq({"person_0_affiliation"=>["affiliation1", "affiliation2", "affiliation3"], "person_1_last_name"=>["Andronicus"], "person_1_first_name"=>["Titus"], "person_1_role"=>["otherrole1","otherrole2"]})
      person_0_affiliation = @article.find_by_terms({:person=>0}, :affiliation)
      expect(person_0_affiliation[0].text).to eq "affiliation1"
      expect(person_0_affiliation[1].text).to eq "affiliation2"
      expect(person_0_affiliation[2].text).to eq "affiliation3"

      person_1_last_names = @article.find_by_terms({:person=>1}, :last_name)
      expect(person_1_last_names.length).to eq 1
      expect(person_1_last_names.first.text).to eq "Andronicus"

      person_1_first_names = @article.find_by_terms({:person=>1}, :first_name)
      expect(person_1_first_names.first.text).to eq "Titus"

      person_1_roles = @article.find_by_terms({:person=>1}, :role)
      expect(person_1_roles[0].text).to eq "otherrole1"
      expect(person_1_roles[1].text).to eq "otherrole2"
    end

    it "should allow setting a blank string " do
      @article.update_values([:abstract]=>[''])
      expect(@article.term_values(:abstract)).to eq [""]
    end

    it "should call term_value_update if the corresponding node already exists" do
      expect(@article).to receive(:term_value_update).with('//oxns:titleInfo/oxns:title', 0, "My New Title")
      @article.update_values( {[:title_info, :main_title] => "My New Title"} )
    end

    it "should call term_values_append if the corresponding node does not already exist or if the requested index is -1" do
      expected_args = {
        # :parent_select => OM::Samples::ModsArticle.terminology.xpath_with_indexes(*[{:person=>0}]) ,
        :parent_select => [{:person=>0}],
        :parent_index => 0,
        :template => [:person, :role],
        :values => "My New Role"
      }
      expect(@article).to receive(:term_values_append).with(expected_args).twice
      @article.update_values( {[{:person=>0}, {:role => 6}] => "My New Role"} )
      @article.update_values( {[{:person=>0}, {:role => 7}] => "My New Role"} )
    end

    it "should support updating attribute values" do
      pointer = [:title_info, :language]
      test_val = "language value"
      @article.update_values( {pointer=>test_val} )
      expect(@article.term_values(*pointer).first).to eq test_val
    end

    it "should not get tripped up on root nodes" do
      @article.update_values([:title_info]=>["york", "mangle","mork"])
      expect(@article.term_values(*[:title_info])).to eq ["york", "mangle", "mork"]
    end

    it "should destringify the field key/find_by_terms_and_value pointer" do
      expected_result = {"person_0_role"=>["the role"]}
      expect(@article.update_values( { [{":person"=>"0"}, "role"]=>"the role" })).to eq expected_result
      expect(@article.update_values( { [{"person"=>"0"}, "role"]=>"the role" })).to eq expected_result
      expect(@article.update_values( { [{:person=>0}, :role]=>"the role" })).to eq expected_result
    end

    it "should replace stuff with the same value (in this case 'one')" do
      @article.update_values( { [{:person=>0}, :role]=>["one"] })
      @article.update_values( { [{:person=>0}, :role]=>["one", "two"] })
      expect(@article.term_values( {:person=>0}, :role)).to eq ["one", "two"]
    end

    it "should traverse named term proxies transparently" do
      expect(@article.term_values( :journal, :issue, :start_page)).not_to eq ["108"]
      @article.update_values( { ["journal", "issue", "start_page"]=>"108" } )
      expect(@article.term_values( :journal, :issue, :start_page)).to eq ["108"]
      expect(@article.term_values( :journal, :issue, :pages, :start)).to eq ["108"]
    end

    it "should create the necessary ancestor nodes when necessary" do
      expect(@sample.find_by_terms(:person).length).to eq(4)
      @sample.update_values([{:person=>8}, :role, :text]=>"my role")
      person_entries = @sample.find_by_terms(:person)
      expect(person_entries.length).to eq 5
      expect(person_entries[4].search("./ns3:role").first.text).to eq "my role"
    end

    it "should create deep trees of ancestor nodes" do
      result = @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>"434" })
      expect(@article.find_by_terms({:journal=>0}, :issue).length).to eq 2
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages).length).to eq 1
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).length).to eq 1
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).first.text).to eq "434"
      #Last argument is a filter, we must explicitly pass no filter
      expect(@article.class.terminology.xpath_with_indexes(:subject, {:topic=>1}, {})).to eq '//oxns:subject/oxns:topic[2]'
      expect(@article.find_by_terms(:subject, {:topic => 1}, {}).text).to eq "TOPIC 2"
    end

    it "should accommodate appending term values with apostrophes in them"  do
      expect(@article.find_by_terms(:person, :description)).to be_empty  # making sure that there's no description node -- forces a value_append
      terms_update_hash =  {[:person, :description]=>" 'phrul gyi lde mig"}
      result = @article.update_values(terms_update_hash)
      expect(@article.term_values(:person, :description)).to include(" 'phrul gyi lde mig")
    end

    it "should support inserting nodes with namespaced attributes" do
      @sample.update_values({['title_info', 'french_title']=>'Le Titre'})
      expect(@sample.term_values('title_info', 'french_title')).to eq ['Le Titre']
    end

    it "should support inserting attributes" do
      skip "HYDRA-415"
      @sample.update_values({['title_info', 'language']=>'Le Titre'})
      expect(@sample.term_values('title_info', 'french_title')).to eq ['Le Titre']
    end

    it "should support inserting namespaced attributes" do
      skip "HYDRA-415"
      @sample.update_values({['title_info', 'main_title', 'main_title_lang']=>'eng'})
      expect(@sample.term_values('title_info', 'main_title', 'main_title_lang')).to eq ['eng']
      ## After a proxy
      expect(@article.term_values(:title,:main_title_lang)).to eq ['eng']
    end

    ### Examples copied over form nokogiri_datastream_spec

    it "should apply submitted hash to corresponding datastream field values" do
      result = @article.update_values( {[{":person"=>"0"}, "first_name"]=>["Billy", "Bob", "Joe"] })
      expect(result).to eq({"person_0_first_name"=>["Billy", "Bob", "Joe"]})
      # xpath = ds.class.xpath_with_indexes(*field_key)
      # result = ds.term_values(xpath)
      expect(@article.term_values({:person=>0}, :first_name)).to eq ["Billy","Bob","Joe"]
      expect(@article.term_values('//oxns:name[@type="personal"][1]/oxns:namePart[@type="given"]')).to eq ["Billy","Bob","Joe"]
    end
    it "should support single-value arguments (as opposed to a hash of values with array indexes as keys)" do
      # In other words, { [:journal, :title_info]=>"dork" } should have the same effect as { [:journal, :title_info]=>{"0"=>"dork"} }
      result = @article.update_values( { [{":person"=>"0"}, "role"]=>"the role" } )
      expect(result).to eq({"person_0_role"=>["the role"]})
      expect(@article.term_values({:person=>0}, :role).first).to eq "the role"
      expect(@article.term_values('//oxns:name[@type="personal"][1]/oxns:role').first).to eq "the role"
    end
    it "should do nothing if field key is a string (must be an array or symbol).  Will not accept xpath queries!" do
      xml_before = @article.to_xml
      expect(@article.update_values( { "fubar"=>"the role" } )).to eq({})
      expect(@article.to_xml).to eq xml_before
    end
    it "should do nothing if there is no term corresponding to the given field key" do
      xml_before = @article.to_xml
      expect(@article.update_values( { [{"fubar"=>"0"}]=>"the role" } )).to eq({})
      expect(@article.to_xml).to eq xml_before
    end

    it "should work for text fields" do
      att= {[{"person"=>"0"},"description"]=>["mork", "york"]}
      result = @article.update_values(att)
      expect(result).to eq({"person_0_description"=>["mork", "york"]})
      expect(@article.term_values({:person=>0},:description)).to eq ['mork', 'york']
      att= {[{"person"=>"0"},{"description" => 2}]=>"dork"}
      result2 = @article.update_values(att)
      expect(result2).to eq({"person_0_description_2"=>["dork"]})
      expect(@article.term_values({:person=>0},:description)).to eq ['mork', 'york', 'dork']
    end

    it "should append nodes at the specified index if possible" do
      @article.update_values([:journal, :title_info]=>["all", "for", "the"])
      att = {[:journal, {:title_info => 3}]=>'glory'}
      result = @article.update_values(att)
      expect(result).to eq({"journal_title_info_3"=>["glory"]})
      expect(@article.term_values(:journal, :title_info)).to eq ["all", "for", "the", "glory"]
    end

    it "should remove extra nodes if fewer are given than currently exist" do
      @article.update_values([:journal, :title_info]=>%W(one two three four five))
      result = @article.update_values({[:journal, :title_info]=>["six", "seven"]})
      expect((@article.term_values(:journal, :title_info))).to eq ["six", "seven"]
    end

    it "should append values to the end of the array if the specified index is higher than the length of the values array" do
      att = {[:journal, :issue, :pages, {:end => 3}]=>'108'}
      expect(@article.term_values(:journal, :issue, :pages, :end)).to eq []
      result = @article.update_values(att)
      expect(result).to eq({"journal_issue_pages_end_3"=>["108"]})
      expect(@article.term_values(:journal, :issue, :pages, :end)).to eq ["108"]
    end

    it "should allow deleting of values and should delete values so that to_xml does not return emtpy nodes" do
      att= {[:journal, :title_info]=>["york", "mangle","mork"]}
      @article.update_values(att)
      expect(@article.term_values(:journal, :title_info)).to eq ['york', 'mangle', 'mork']

      @article.update_values({[:journal, {:title_info => 1}]=>nil})
      expect(@article.term_values(:journal, :title_info)).to eq ['york', 'mork']

      @article.update_values({[:journal, {:title_info => 0}]=>:delete})
      expect(@article.term_values(:journal, :title_info)).to eq ['mork']
    end

    describe "delete_on_update?" do

      before(:each) do
        att= {[:journal, :title_info]=>["york", "mangle","mork"]}
        @article.update_values(att)
        expect(@article.term_values(:journal, :title_info)).to eq ['york', 'mangle', 'mork']
      end

      it "by default, setting to nil deletes the node" do
        @article.update_values({[:journal, {:title_info => 1}]=>nil})
        expect(@article.term_values(:journal, :title_info)).to eq ['york', 'mork']
      end

      it "if delete_on_update? returns false, setting to nil won't delete node" do
        allow(@article).to receive('delete_on_update?').and_return(false)
        @article.update_values({[:journal, {:title_info => 1}]=>""})
        expect(@article.term_values(:journal, :title_info)).to eq ['york', '', 'mork']
      end

    end

    it "should retain other child nodes when updating a text content term and shoud not append an additional text node but update text in place" do
      expect(@article.term_values(:name,:name_content)).to eq ["Describes a person"]
      @article.update_values({[:name, :name_content]=>"Test text"})
      expect(@article.term_values(:name,:name_content)).to eq ["Test text"]
      expect(@article.find_by_terms(:name).children.length()).to eq 35
    end

  end

  describe ".term_values_append" do
    before :each do
      @expected_result = '<ns3:name type="personal">
      <ns3:namePart type="family">Berners-Lee</ns3:namePart>
      <ns3:namePart type="given">Tim</ns3:namePart>
      <ns3:role>
          <ns3:roleTerm type="text" authority="marcrelator">creator</ns3:roleTerm>
          <ns3:roleTerm type="code" authority="marcrelator">cre</ns3:roleTerm>
      </ns3:role>
  <ns3:affiliation>my new value</ns3:affiliation><ns3:affiliation>another new value</ns3:affiliation></ns3:name>'
    end

    it "looks up the parent using :parent_select, uses :parent_index to choose the parent node from the result set, uses :template to build the node(s) to be inserted, inserts the :values(s) into the node(s) and adds the node(s) to the parent" do
      @sample.term_values_append(
        :parent_select => [:person, {:first_name=>"Tim", :last_name=>"Berners-Lee"}] ,
        :parent_index => :first,
        :template => [:person, :affiliation],
        :values => ["my new value", "another new value"]
      )
    end

    it "should accept parent_select and template [term_reference, find_by_terms_and_value_opts] as argument arrays for generators/find_by_terms_and_values" do
      # this appends two affiliation nodes into the first person node whose name is Tim Berners-Lee
      expect(@sample.term_values_append(
        :parent_select => [:person, {:first_name=>"Tim", :last_name=>"Berners-Lee"}] ,
        :parent_index => :first,
        :template => [:person, :affiliation],
        :values => ["my new value", "another new value"]
      ).to_xml).to eq(@expected_result)

      expect(@sample.find_by_terms(:person, {:first_name=>"Tim", :last_name=>"Berners-Lee"}).first.to_xml).to eq(@expected_result)
    end

    it "should support adding attribute values" do
      pointer = [{:title_info=>0}, :language]
      test_val = "language value"
      @article.term_values_append(
        :parent_select => [{:title_info=>0}],
        :parent_index => 0,
        :template => [{:title_info=>0}, :language],
        :values => test_val
      )
      expect(@article.term_values(*pointer).first).to eq(test_val)
    end

    it "should accept symbols as arguments for generators/find_by_terms_and_values" do
      # this appends a role of "my role" into the third "person" node in the document
      @sample.term_values_append(
        :parent_select => :person,
        :parent_index => 3,
        :template => :role,
        :values => "my role"
      )
      expect(@sample.find_by_terms(:person)[3].search("./ns3:role[3]").first.text).to eq("my role")
    end

    it "should accept parent_select as an (xpath) string and template as a (template) string" do
      # this uses the provided template to add a node into the first node resulting from the xpath '//oxns:name[@type="personal"]'
      expected_result = "<ns3:name type=\"personal\">\n      <ns3:namePart type=\"family\">Berners-Lee</ns3:namePart>\n      <ns3:namePart type=\"given\">Tim</ns3:namePart>\n      <ns3:role>\n          <ns3:roleTerm type=\"text\" authority=\"marcrelator\">creator</ns3:roleTerm>\n          <ns3:roleTerm type=\"code\" authority=\"marcrelator\">cre</ns3:roleTerm>\n      </ns3:role>\n  <ns3:role type=\"code\" authority=\"marcrelator\"><ns3:roleTerm>creator</ns3:roleTerm></ns3:role></ns3:name>"

      expect(@sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role', @sample.ox_namespaces).length).to eq(1)

      @sample.term_values_append(
        :parent_select =>'//oxns:name[@type="personal"]',
        :parent_index => 0,
        :template => 'xml.role { xml.roleTerm( \'#{builder_new_value}\', :type=>\'code\', :authority=>\'marcrelator\') }',
        :values => "founder"
      )

      expect(@sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role', @sample.ox_namespaces).length).to eq(2)
      expect(@sample.ng_xml.xpath('//oxns:name[@type="personal" and position()=1]/oxns:role[last()]/oxns:roleTerm', @sample.ox_namespaces).first.text).to eq("founder")

      # @sample.find_by_terms_and_value(:person).first.to_xml.should == expected_result
    end

    it "should support more complex mixing & matching" do
      skip "not working because builder_template is not returning the correct template (returns builder for role instead of roleTerm)"
      expect(@sample.ng_xml.xpath('//oxns:name[@type="personal"][2]/oxns:role[1]/oxns:roleTerm', @sample.ox_namespaces).length).to eq(2)
      @sample.term_values_append(
        :parent_select =>'//oxns:name[@type="personal"][2]/oxns:role',
        :parent_index => 0,
        :template => [ :person, :role, :text, {:attributes=>{"authority"=>"marcrelator"}} ],
        :values => "foo"
      )

      expect(@sample.ng_xml.xpath('//oxns:name[@type="personal"][2]/oxns:role[1]/oxns:roleTerm', @sample.ox_namespaces).length).to eq(3)
      expect(@sample.find_by_terms({:person=>1},:role)[0].search("./oxns:roleTerm[@type=\"text\" and @authority=\"marcrelator\"]", @sample.ox_namespaces).first.text).to eq("foo")
    end

    it "should create the necessary ancestor nodes when you insert a new term value" do
      expect(@sample.find_by_terms(:person).length).to eq(4)
      @sample.term_values_append(
        :parent_select => :person,
        :parent_index => 8,
        :template => :role,
        :values => "my role"
      )
      person_entries = @sample.find_by_terms(:person)
      expect(person_entries.length).to eq(5)
      expect(person_entries[4].search("./ns3:role").first.text).to eq("my role")
    end

    it "should create the necessary ancestor nodes for deep trees of ancestors" do
      deep_pointer = [{:journal=>0}, {:issue=>3}, :pages, :start]
      expect(@article.find_by_terms({:journal=>0}).length).to eq(1)
      expect(@article.find_by_terms({:journal=>0}, :issue).length).to eq(1)
      @article.term_values_append(
        :parent_select => deep_pointer[0..deep_pointer.length-2] ,
        :parent_index => 0,
        :template => deep_pointer,
        :values => "451"
      )
      expect(@article.find_by_terms({:journal=>0}, :issue).length).to eq(2)
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages).length).to eq(1)
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).length).to eq(1)
      expect(@article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).first.text).to eq("451")

    end
  end

  describe ".term_value_update" do

    it "should accept an xpath as :parent_select" do
      sample_xpath = '//oxns:name[@type="personal"][4]/oxns:role/oxns:roleTerm[@type="text"]'
      @sample.term_value_update(sample_xpath,1,"artist")
      expect(@sample.ng_xml.xpath(sample_xpath, @sample.ox_namespaces)[1].text).to eq("artist")
    end

    it "if :select is provided, should update the first node provided by that xpath statement" do
      sample_xpath = '//oxns:name[@type="personal"][1]/oxns:namePart[@type="given"]'
      @sample.term_value_update(sample_xpath,0,"Timmeh")
      expect(@sample.ng_xml.xpath(sample_xpath, @sample.ox_namespaces).first.text).to eq("Timmeh")
    end

    it "should replace the existing node if you pass a template and values" do
      skip
      @sample.term_value_update(
        :parent_select =>'//oxns:name[@type="personal"]',
        :parent_index => 1,
        :template => [ :person, :role, {:attributes=>{"type"=>"code", "authority"=>"marcrelator"}} ],
        :value => "foo"
      )
      expect(1).to eq(2)
    end
    it "should delete nodes if value is :delete or nil" do
      @article.update_values([:title_info]=>["york", "mangle","mork"])
      xpath = @article.class.terminology.xpath_for(:title_info)

      @article.term_value_update([:title_info], 1, nil)
      expect(@article.term_values(:title_info)).to eq(['york', 'mork'])

      @article.term_value_update([:title_info], 1, :delete)
      expect(@article.term_values(:title_info)).to eq(['york'])
    end
    it "should create empty nodes if value is empty string" do
      @article.update_values([:title_info]=>["york", '', "mork"])
      expect(@article.term_values(:title_info)).to eq(['york', "", "mork"])
    end
  end

  describe ".term_value_delete" do
    it "should accept an xpath query as :select option" do
      generic_xpath  = '//oxns:name[@type="personal" and position()=4]/oxns:role'
      specific_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role[oxns:roleTerm="visionary"]'
      select_xpath   = '//oxns:name[@type="personal" and position()=4]/oxns:role[last()]'

      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(2)
      expect(@sample.find_by_terms_and_value(specific_xpath).length).to eq(1)

      @sample.term_value_delete(
        :select =>select_xpath
      )
      # Check that we're finishing with 1 role
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(1)
      # Check that the specific node we want to delete no longer exists
      expect(@sample.find_by_terms_and_value(specific_xpath).length).to eq(0)
    end
    it "should accept :parent_select, :parent_index and :parent_index options instead of a :select" do

      generic_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role/oxns:roleTerm'
      specific_xpath = '//oxns:name[@type="personal" and position()=4]/oxns:role[oxns:roleTerm="visionary"]'

      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(4)
      expect(@sample.find_by_terms_and_value(specific_xpath).length).to eq(1)

      # this is attempting to delete the last child (in this case roleTerm) from the 3rd role in the document.
      @sample.term_value_delete(
        :parent_select => [:person, :role],
        :parent_index => 3,
        :child_index => :last
      )

      # Check that we're finishing with 1 role
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(3)
      # Check that the specific node we want to delete no longer exists
      expect(@sample.find_by_terms_and_value(specific_xpath).length).to eq(1)
    end
    it "should work if only :parent_select and :parent_index are provided" do
      generic_xpath = '//oxns:name[@type="personal"]/oxns:role'
      # specific_xpath = '//oxns:name[@type="personal"]/oxns:role'

      # Check that we're starting with 2 roles
      # Check that the specific node we want to delete exists
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(4)
      # @sample.find_by_terms_and_value(specific_xpath).length.should == 1

      @sample.term_value_delete(
        :parent_select => [:person, :role],
        :child_index => 3
      )
      # Check that we're finishing with 1 role
      expect(@sample.find_by_terms_and_value(generic_xpath).length).to eq(3)
    end
  end

  describe "build_ancestors" do
    it "should raise an error if it cant find a starting point for building from" do
      expect { @empty_sample.build_ancestors( [:journal, :issue], 0) }.to raise_error(OM::XML::TemplateMissingException, "Cannot insert nodes into the document because it is empty.  Try defining self.xml_template on the OM::Samples::ModsArticle class.")
    end
  end

end
