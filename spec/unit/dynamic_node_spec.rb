require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::DynamicNode" do
  
  before(:each) do
    @sample = OM::Samples::ModsArticle.from_xml( fixture( File.join("test_dummy_mods.xml") ) )
    @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
  end
  
  describe "dynamically created nodes" do

    it "should return build an array of values from the nodeset corresponding to the given term" do
      expected_values = ["Berners-Lee", "Jobs", "Wozniak", "Klimt"]
      result = @sample.person.last_name
      result.length.should == expected_values.length
      expected_values.each {|v| result.should include(v)}
    end

    it "should be able to set first level elements" do
      @article.abstract = "My Abstract"
      @article.abstract.should == ["My Abstract"]
    end

    describe "setting attributes" do
      it "when they exist" do
        @article.title_info(0).main_title.main_title_lang = "ger"
        @article.title_info(0).main_title.main_title_lang.should == ["ger"]
      end
      it "when they don't exist" do
        title = @article.title_info(0)
        title.language = "rus"
        @article.title_info(0).language.should == ["rus"]
      end

    end

    it "should find elements two deep" do
      #TODO reimplement so that method_missing with name is only called once.  Create a new method for name.
      @article.name.name_content.val.should == ["Describes a person"]
      @article.name.name_content.should == ["Describes a person"]
      @article.name.name_content(0).should == ["Describes a person"]
    end

    it "should not find elements that don't  exist" do
      lambda {@article.name.hedgehog}.should raise_exception NoMethodError
    end

    it "should allow you to call methods on the return value" do
      @article.name.name_content.first.should == "Describes a person"
    end

    it "Should work with proxies" do
      @article.title.should == ["ARTICLE TITLE HYDRANGEA ARTICLE 1", "Artikkelin otsikko Hydrangea artiklan 1", "TITLE OF HOST JOURNAL"]
      @article.title.main_title_lang.should == ['eng']

      @article.title(1).to_pointer.should == [{:title => 1}]

      @article.journal_title.xpath.should == "//oxns:relatedItem[@type=\"host\"]/oxns:titleInfo/oxns:title"
      @article.journal_title.should == ["TITLE OF HOST JOURNAL"]
    end

    it "Should be addressable to a specific node" do
      @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>{"0"=>"434"} })

      @article.subject.topic(1).to_pointer == [:subject, {:topic => 1}]
      @article.journal(0).issue.length.should == 2
      @article.journal(0).issue(1).pages.to_pointer == [{:journal=>0}, {:issue=>1}, :pages]
      @article.journal(0).issue(1).pages.length.should == 1
      @article.journal(0).issue(1).pages.start.length.should == 1
      @article.journal(0).issue(1).pages.start.first.should == "434"

      @article.subject.topic(1).should == ["TOPIC 2"]
      @article.subject.topic(1).xpath.should == "//oxns:subject/oxns:topic[2]"
    end
    
    describe ".nodeset" do
      it "should return a Nokogiri NodeSet" do
        @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>{"0"=>"434"} })
        nodeset = @article.journal(0).issue(1).pages.start.nodeset
        nodeset.should be_kind_of Nokogiri::XML::NodeSet
        nodeset.length.should == @article.journal(0).issue(1).pages.start.length
        nodeset.first.text.should == @article.journal(0).issue(1).pages.start.first
      end
    end

    it "should append nodes at the specified index if possible, setting dirty to true if the object responds to dirty" do
      @article.stubs(:respond_to?).with(:dirty=).returns(true)
      @article.expects(:dirty=).with(true).twice
      @article.journal.title_info = ["all", "for", "the"]
      @article.journal.title_info(3, 'glory')
      @article.term_values(:journal, :title_info).should == ["all", "for", "the", "glory"]
    end
  
  end
end
