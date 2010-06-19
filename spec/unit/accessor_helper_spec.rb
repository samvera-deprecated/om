require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "OX::AccesorHelper" do
  
  before(:all) do
    class AccessorTest
    
      attr_accessor :ng_xml
      
      include OX::AccessorHelper
      #accessor :title, :relative_xpath=>[:titleInfo, :title]}}         
    
      accessor :title, :relative_xpath=>'oxns:titleInfo/oxns:title', :children=>[
        {:language =>{:relative_xpath=>[{:attribute=>"lang"}] }}
        ]  # this allows you to access the language attribute as if it was a regular child accessor
      accessor :abstract
      accessor :topic_tag, :relative_xpath=>[:subject, :topic]
      accessor :person, :children=>[:last_name, :first_name, :affiliation, :role]
      accessor :organization, :children=>[:role] 
      accessor :conference, :children=>[:role]
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
    @sample = AccessorTest.new
    @sample.ng_xml = fixture( File.join("mods_articles", "hydrangea_article1.xml") )
  end
  
  describe '#accessor' do
    it "should populate the .accessors hash" do
      AccessorTest.accessors[:abstract][:relative_xpath].should == "oxns:abstract"
      
      AccessorTest.accessors[:journal][:relative_xpath].should == 'oxns:relatedItem[@type="host"]'
      AccessorTest.accessors[:journal][:children][:issue][:relative_xpath].should == "oxns:part"
      pp AccessorTest.accessors[:journal]
      AccessorTest.accessors[:journal][:children][:issue][:children][:end_page][:relative_xpath].should == 'oxns:extent[@unit="pages"]/oxns:end'
    end
  end
  
  describe ".retrieve" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of accessor keys and array/nodeset indexes" do
      @sample.retrieve( [:person] ).length.should == 2
      
      @sample.retrieve( [:person, 1] ).first.should == @sample.ng_xml.xpath_at('oxns:name[@type="person" and positon()=2]')
      @sample.retrieve( [:person, 1, :first_name] ).class.should == Nokogiri::NodeSet
      @sample.retrieve( [:person, 1, :first_name] ).first.text.should == "Siddartha"
    end
    
    it "should support accessors whose relative_xpath is a lookup array instead of an xpath string" do
      AccessorTest.accessors[:title][:children][:language][:relative_xpath].should == [{:attribute=>"lang"}]
      @sample.retrieve( [:title, 1] ).first.text.should == "Artikkelin otsikko Hydrangea artiklan 1"
      @sample.retrieve( [:title, 1, :language] ).first.text.should == "finnish"
    end
    
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of accessor keys and array/nodeset indexes" do
      mock_person = mock("person")
      mock_persons_set = ["foo", mock_person]
      mock_first_names_set = mock("first name nodeset")
      
      @sample.ng_xml.expects(:xpath).with('oxns:name[@type="person"]').returns(mock_persons_set)
      mock_persons.expects(:xpath).with('namePart[@type="given"]').returns(mock_first_names_set)
      
      @sample.retrieve(:person, 1, :first_name).should == mock_first_names_set 
    end
    
  end
  
  describe ".retrieve_at" do
    it "should return the first node in the resulting set (uses Nokogiri xpath_at)" do
      pending "might be able to make this implicit in the last value of call to .retrieve"
      @sample.retrieve_at(:person, 1, :first_name).text.should == "Siddartha"
      @sample.retrieve_at(:person, 1, :first_name).should == @sample.retrieve( :person, 1, :first_name).first
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
  
  # describe "#accessor_xpath" do
  #   it "should return the xpath given in the call to #accessor" do
  #     AccessorTest.accessor_xpath( [:abstract] ).should == 'oxns:abstract'
  #   end   
  #   # Note: Ruby array indexes begin from 0.  In xpath queries (which start from 1 instead of 0), this will be translated accordingly.
  #   it "should prepend the xpath for any parent nodes, inserting calls to xpath:position() function where necessary" do
  #     AccessorTest.accessor_xpath( [:conference, 0, :role, 1, :text] ).should == 'oxns:name[@type="conference" and positon()=1]/oxns:role[position()=2]/roleTerm[@type="text"]'
  #   end
  #   it "should prepend the xpath for any parent nodes" do
  #     AccessorTest.accessor_xpath( [:conference, conference_index, :text_role] ).should == 'oxns:name[@type="conference"]/oxns:role'
  #   end
  # end
  # describe ".accessor_xpath" do
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

#    ORIGINAL NOTES...
  # tmpl = ModsDatastream.new
  # fixturemods = fixture("RUBRIC_MODS_template.xml")
  # mods_ds = ModsDatastream.from_xml(fixturemods)
  # 
  # # simple ones
  # title, title_language, organization, conference, abstract
  # topic_tag
  # 
  # mods_ds.title_values
  # mods_ds.title_language_values
  # 
  # 
  # # these must be grouped together within person nodes
  # 
  # person_last_name, person_first_name, person_affiliation, person_role
  # 
  # mods_ds.person[1].role_values
  # mods_ds.person[1].first_name_values
  # 
  # # these must map to stuff within relatedItem nodes...
  # 
  # journal_title, publisher, issn, issue, start_page, end_page
  # 
  # .journal_title_values
  # .publisher_values
  # .issn_values
  # 
  # mods_ds.publisher[1].journal[0].start_page_values  # creates solr field publisher_journal_start_page  OR publisher_1_journal_0_start_page
  # mods_ds.publisher[1].journal.last.title_values
end