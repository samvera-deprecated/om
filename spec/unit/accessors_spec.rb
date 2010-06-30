require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "nokogiri"
require "om"

describe "OM::XML::Accessors" do
  
  before(:all) do
    class AccessorTest
    
      include OM::XML::Container      
      include OM::XML::Accessors
      #accessor :title, :relative_xpath=>[:titleInfo, :title]}}         
    
      accessor :title_info, :relative_xpath=>'oxns:titleInfo', :children=>[
        {:main_title=>{:relative_xpath=>'oxns:title'}},         
        {:language =>{:relative_xpath=>{:attribute=>"lang"} }}
        ]  # this allows you to access the language attribute as if it was a regular child accessor
      accessor :abstract
      accessor :topic_tag, :relative_xpath=>'oxns:subject/oxns:topic'
      accessor :person, :relative_xpath=>'oxns:name[@type="personal"]',  :children=>[
        {:last_name=>{:relative_xpath=>'oxns:namePart[@type="family"]'}}, 
        {:first_name=>{:relative_xpath=>'oxns:namePart[@type="given"]'}}, 
        {:institution=>{:relative_xpath=>'oxns:affiliation'}}, 
        {:role=>{:children=>[
          {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
          {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
        ]}}
      ]
      accessor :organization, :relative_xpath=>'oxns:name[@type="institutional"]', :children=>[
        {:role=>{:children=>[
          {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
          {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
        ]}}
      ]
      accessor :conference, :relative_xpath=>'oxns:name[@type="conference"]', :children=>[
        {:role=>{:children=>[
          {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
          {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
        ]}}
      ]
      accessor :journal, :relative_xpath=>'oxns:relatedItem[@type="host"]', :children=>[
        # allows for children that are hashes...
        # this allows for more robust handling of nested values (in generating views and when generating solr field names)
          {:title=>{:relative_xpath=>'oxns:titleInfo/oxns:title'}}, 
          {:publisher=>{:relative_xpath=>'oxns:originInfo/oxns:publisher'}},
          {:issn=>{:relative_xpath=>'oxns:identifier[@type="issn"]'}}, 
          {:date_issued=>{:relative_xpath=>'oxns:originInfo/oxns:dateIssued'}},
          {:issue => {:relative_xpath=>"oxns:part", :children=>[
            {:volume=>{:relative_xpath=>'oxns:detail[@type="volume"]'}},
            {:level=>{:relative_xpath=>'oxns:detail[@type="level"]'}},
            {:start_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:start'}},
            {:end_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:end'}},
            {:publication_date=>{:relative_xpath=>'oxns:date'}}
          ]}}
      ]    
    end
    
  end

  before(:each) do
    article_xml = fixture( File.join("mods_articles", "hydrangea_article1.xml") )
    @sample = AccessorTest.from_xml(article_xml)
  end
  
  describe '#accessor' do
    it "should populate the .accessors hash" do
      AccessorTest.accessors[:abstract][:relative_xpath].should == "oxns:abstract"
      AccessorTest.accessors[:journal][:relative_xpath].should == 'oxns:relatedItem[@type="host"]'
      AccessorTest.accessors[:journal][:children][:issue][:relative_xpath].should == "oxns:part"
      AccessorTest.accessors[:journal][:children][:issue][:children][:end_page][:relative_xpath].should == 'oxns:extent[@unit="pages"]/oxns:end'

      AccessorTest.accessors[:person][:children][:role][:children][:text][:relative_xpath].should == 'oxns:roleTerm[@type="text"]'
    end
  end
  
  describe ".retrieve" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of accessor keys and array/nodeset indexes" do
      @sample.retrieve( :person ).length.should == 2
      
      @sample.retrieve( {:person=>1} ).first.should == @sample.ng_xml.xpath('//oxns:name[@type="personal"][2]', "oxns"=>"http://www.loc.gov/mods/v3").first
      @sample.retrieve( {:person=>1}, :first_name ).class.should == Nokogiri::XML::NodeSet
      @sample.retrieve( {:person=>1}, :first_name ).first.text.should == "Siddartha"
    end
    
    it "should support accessors whose relative_xpath is a lookup array instead of an xpath string" do
      # pending "this only impacts scenarios where we want to display & edit"
      AccessorTest.accessors[:title_info][:children][:language][:relative_xpath].should == {:attribute=>"lang"}
      # @sample.retrieve( :title, 1 ).first.text.should == "Artikkelin otsikko Hydrangea artiklan 1"
      @sample.retrieve( {:title_info=>1}, :language ).first.text.should == "finnish"
    end
    
    it "should support xpath queries as the pointer" do
      @sample.retrieve('//oxns:name[@type="personal"][1]/oxns:namePart[1]').first.text.should == "FAMILY NAME"
    end
    
    it "should return nil if the xpath fails to generate" do
      @sample.retrieve( {:foo=>20}, :bar ).should == nil
    end
    
  end

  describe "generated accessor methods" do
    it "should mix accessor methods into nodesets so you can use regular array syntax to access stuff" do
      pending "This is tempting, but somewhat difficult to implement and potentially slow at runtime.  Might never be worth it?"
      @sample.persons.length.should == 2
      @sample.persons[1].first_name.text.should == "Siddartha" 
      @sample.persons.last.roles.length.should == 1
      @sample.persons.last.roles[0].text.should == "teacher"
    end
  end
  
  describe "#accessor_info" do
    it "should return the xpath given in the call to #accessor" do
      AccessorTest.accessor_info( :abstract ).should == AccessorTest.accessors[:abstract]
    end
    it "should return the xpath given in the call to #accessor" do
      AccessorTest.accessor_info( :abstract ).should == AccessorTest.accessors[:abstract]
    end
    it "should dig into the accessors hash as far as you want, ignoring index values" do      
      AccessorTest.accessor_info( *[{:conference=>0}, {:role=>1}, :text] ).should == AccessorTest.accessors[:conference][:children][:role][:children][:text]
      AccessorTest.accessor_info( {:conference=>0}, {:role=>1}, :text ).should == AccessorTest.accessors[:conference][:children][:role][:children][:text]
      
      AccessorTest.accessor_info( :conference, :role, :text ).should  == AccessorTest.accessors[:conference][:children][:role][:children][:text]
    end
  end
    
  describe "#accessor_xpath" do
    it "should return the xpath given in the call to #accessor" do
      AccessorTest.accessor_xpath( :abstract ).should == '//oxns:abstract'
    end   
    # Note: Ruby array indexes begin from 0.  In xpath queries (which start from 1 instead of 0), this will be translated accordingly.
    it "should prepend the xpath for any parent nodes, inserting calls to xpath array lookup where necessary" do
      AccessorTest.accessor_xpath( {:conference=>0}, {:role=>1}, :text ).should == '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
    end
    it "should support xpath queries as argument" do
      AccessorTest.accessor_xpath('//oxns:name[@type="personal"][1]/oxns:namePart').should == '//oxns:name[@type="personal"][1]/oxns:namePart'
    end
    it "should return nil if no accessor_info is available" do
      AccessorTest.accessor_xpath( :sample_undeclared_accessor ).should == nil
    end
    it "should be idempotent" do
      AccessorTest.accessor_xpath( *[{:title_info=>2}, :main_title] ).should == "//oxns:titleInfo[3]/oxns:title"
      AccessorTest.accessor_xpath( *[{:title_info=>2}, :main_title] ).should == "//oxns:titleInfo[3]/oxns:title"
      AccessorTest.accessor_xpath( *[{:title_info=>2}, :main_title] ).should == "//oxns:titleInfo[3]/oxns:title"
    end
  end
  
  describe "#accessor_generic_name" do
    it "should generate a generic accessor name based on an array of pointers" do
      AccessorTest.accessor_generic_name( {:conference=>0}, {:role=>1}, :text ).should == "conference_role_text"
      AccessorTest.accessor_generic_name( *[{:conference=>0}, {:role=>1}, :text] ).should == "conference_role_text"      
    end
  end
  
  describe "#accessor_hierarchical_name" do
    it "should generate a specific accessor name based on an array of pointers and indexes" do
      AccessorTest.accessor_hierarchical_name( {:conference=>0}, {:role=>1}, :text ).should == "conference_0_role_1_text"
      AccessorTest.accessor_hierarchical_name( *[{:conference=>0}, {:role=>1}, :text] ).should == "conference_0_role_1_text"
    end
  end
  
  describe '#generate_accessors_from_properties' do
    before(:each) do
      class AccessorTest2
        include OM::XML::Accessors
      end
    end
    
    it "should generate accessors from the properties hash" do
      sample_properties_hash = {:mods=>{:path=>"mods", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd", :ref=>:mods, :xpath_relative=>"oxns:mods", :xpath_constrained=>"//oxns:mods[contains(\\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:mods", :convenience_methods=>{}}, :person=>{:path=>"name", :attributes=>{:type=>"personal"}, :subelements=>["namePart", "displayForm", "affiliation", :role, "description"], :ref=>:person, :xpath_relative=>"oxns:name[@type=\"personal\"]", :variant_of=>:name_, :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart, \\\"\#{constraint_value}\\\")]", :default_content_path=>"namePart", :xpath=>"//oxns:name[@type=\"personal\"]", :convenience_methods=>{:first_name=>{:path=>"namePart", :attributes=>{:type=>"given"}, :xpath_relative=>"oxns:namePart[@type=\"given\"]", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart[@type=\\\"given\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"given\"]"}, :affiliation=>{:path=>"affiliation", :xpath_relative=>"oxns:affiliation", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:affiliation, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:affiliation"}, :terms_of_address=>{:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}, :xpath_relative=>"oxns:namePart[@type=\"termsOfAddress\"]", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart[@type=\\\"termsOfAddress\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"termsOfAddress\"]"}, :namePart=>{:path=>"namePart", :xpath_relative=>"oxns:namePart", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:namePart"}, :role=>{:path=>"role", :attributes=>[{"type"=>["text", "code"]}, "authority"], :ref=>:role, :xpath_relative=>"oxns:role", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:role, \\\"\#{constraint_value}\\\")]", :parents=>[:name_], :convenience_methods=>{:text=>{:path=>"roleTerm", :attributes=>{:type=>"text"}, :xpath_relative=>"oxns:roleTerm[@type=\"text\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"text\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"text\"]"}, :code=>{:path=>"roleTerm", :attributes=>{:type=>"code"}, :xpath_relative=>"oxns:roleTerm[@type=\"code\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"code\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"code\"]"}}, :xpath=>"//oxns:name[@type=\"personal\"]/oxns:role"}, :displayForm=>{:path=>"displayForm", :xpath_relative=>"oxns:displayForm", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:displayForm, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:displayForm"}, :date=>{:path=>"namePart", :attributes=>{:type=>"date"}, :xpath_relative=>"oxns:namePart[@type=\"date\"]", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart[@type=\\\"date\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"date\"]"}, :family_name=>{:path=>"namePart", :attributes=>{:type=>"family"}, :xpath_relative=>"oxns:namePart[@type=\"family\"]", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:namePart[@type=\\\"family\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:namePart[@type=\"family\"]"}, :description=>{:path=>"description", :xpath_relative=>"oxns:description", :xpath_constrained=>"//oxns:name[@type=\\\"personal\\\" and contains(oxns:description, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name[@type=\"personal\"]/oxns:description"}}}, :name_=>{:path=>"name", :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]}], :subelements=>["namePart", "displayForm", "affiliation", :role, "description"], :ref=>:name_, :xpath_relative=>"oxns:name", :xpath_constrained=>"//oxns:name[contains(oxns:namePart, \\\"\#{constraint_value}\\\")]", :default_content_path=>"namePart", :xpath=>"//oxns:name", :convenience_methods=>{:first_name=>{:path=>"namePart", :attributes=>{:type=>"given"}, :xpath_relative=>"oxns:namePart[@type=\"given\"]", :xpath_constrained=>"//oxns:name[contains(oxns:namePart[@type=\\\"given\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:namePart[@type=\"given\"]"}, :affiliation=>{:path=>"affiliation", :xpath_relative=>"oxns:affiliation", :xpath_constrained=>"//oxns:name[contains(oxns:affiliation, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:affiliation"}, :terms_of_address=>{:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}, :xpath_relative=>"oxns:namePart[@type=\"termsOfAddress\"]", :xpath_constrained=>"//oxns:name[contains(oxns:namePart[@type=\\\"termsOfAddress\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:namePart[@type=\"termsOfAddress\"]"}, :namePart=>{:path=>"namePart", :xpath_relative=>"oxns:namePart", :xpath_constrained=>"//oxns:name[contains(oxns:namePart, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:namePart"}, :role=>{:path=>"role", :attributes=>[{"type"=>["text", "code"]}, "authority"], :ref=>:role, :xpath_relative=>"oxns:role", :xpath_constrained=>"//oxns:name[contains(oxns:role, \\\"\#{constraint_value}\\\")]", :parents=>[:name_], :convenience_methods=>{:text=>{:path=>"roleTerm", :attributes=>{:type=>"text"}, :xpath_relative=>"oxns:roleTerm[@type=\"text\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"text\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"text\"]"}, :code=>{:path=>"roleTerm", :attributes=>{:type=>"code"}, :xpath_relative=>"oxns:roleTerm[@type=\"code\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"code\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"code\"]"}}, :xpath=>"//oxns:name/oxns:role"}, :displayForm=>{:path=>"displayForm", :xpath_relative=>"oxns:displayForm", :xpath_constrained=>"//oxns:name[contains(oxns:displayForm, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:displayForm"}, :description=>{:path=>"description", :xpath_relative=>"oxns:description", :xpath_constrained=>"//oxns:name[contains(oxns:description, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:description"}, :family_name=>{:path=>"namePart", :attributes=>{:type=>"family"}, :xpath_relative=>"oxns:namePart[@type=\"family\"]", :xpath_constrained=>"//oxns:name[contains(oxns:namePart[@type=\\\"family\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:namePart[@type=\"family\"]"}, :date=>{:path=>"namePart", :attributes=>{:type=>"date"}, :xpath_relative=>"oxns:namePart[@type=\"date\"]", :xpath_constrained=>"//oxns:name[contains(oxns:namePart[@type=\\\"date\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:name/oxns:namePart[@type=\"date\"]"}}}, :role=>{:path=>"role", :attributes=>[{"type"=>["text", "code"]}, "authority"], :ref=>:role, :xpath_relative=>"oxns:role", :xpath_constrained=>"//oxns:role[contains(\\\"\#{constraint_value}\\\")]", :parents=>[:name_], :xpath=>"//oxns:role", :convenience_methods=>{:text=>{:path=>"roleTerm", :attributes=>{:type=>"text"}, :xpath_relative=>"oxns:roleTerm[@type=\"text\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"text\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"text\"]"}, :code=>{:path=>"roleTerm", :attributes=>{:type=>"code"}, :xpath_relative=>"oxns:roleTerm[@type=\"code\"]", :xpath_constrained=>"//oxns:role[contains(oxns:roleTerm[@type=\\\"code\\\"], \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:role/oxns:roleTerm[@type=\"code\"]"}}}, :title_info=>{:path=>"titleInfo", :ref=>:title_info, :xpath_relative=>"oxns:titleInfo", :xpath_constrained=>"//oxns:titleInfo[contains(\\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:titleInfo", :convenience_methods=>{:main_title=>{:path=>"title", :xpath_relative=>"oxns:title", :xpath_constrained=>"//oxns:titleInfo[contains(oxns:title, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:titleInfo/oxns:title"}, :language=>{:path=>"@lang", :xpath_relative=>"oxns:@lang", :xpath_constrained=>"//oxns:titleInfo[contains(oxns:@lang, \\\"\#{constraint_value}\\\")]", :xpath=>"//oxns:titleInfo/oxns:@lang"}}}, :unresolved=>{}}
      AccessorTest2.stubs(:properties).returns(sample_properties_hash)
      
      AccessorTest2.accessors.should be_nil
      AccessorTest2.generate_accessors_from_properties.should_not be_nil
      [:mods, :name_, :person, [:person,:first_name],[:person, :role], [:person, :role, :text] ].each do |pointer|
        puts pointer
        ai = AccessorTest2.accessor_info(*pointer)
        ai.should_not be_nil
        ai[:relative_xpath].should_not be_nil
      end
    end
    
  end
  
  # describe ".accessor_xpath (instance method)" do
  #   it "should delegate to the class method" do
  #     AccessorTest.expects(:accessor_xpath).with( [:conference, conference_index, :text_role] )
  #     @sample.accessor_xpath( [:conference, conference_index, :role] )
  #   end
  # end
  # 
  # describe "generated catchall xpaths" do
  #   it "should return an xpath query that will catch all nodes corresponding to the specified accessor" do
  #     AccessorTest.journal_issue_end_page_xpath.should == 'oxns:relatedItem[@type="host"]/oxns:part/oxns:extent[@unit="pages"]/oxns:end'
  #   end
  #   it "should rely on #catchall_xpath" do
  #     AccessorTest.expects(:catchall_xpath).with(:journal, :issue, :end_page)
  #     AccessorTest.journal_issue_end_page_xpath
  #   end
  # end
  # 
  # describe ".catchall_xpath" do
  #   it "should return an xpath query that will catch all nodes corresponding to the specified accessor" do
  #     AccessorTest.catchall_xpath(:journal, :issue, :end_page).should == 'oxns:relatedItem[@type="host"]/oxns:part/oxns:extent[@unit="pages"]/oxns:end'
  #   end
  # end
end