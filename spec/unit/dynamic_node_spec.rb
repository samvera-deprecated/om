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

    it "should find elements two deep" do
      #TODO ensure that method_missing with name is only called once.  Create a new method for name.
      @article.name.name_content.val.should == ["Describes a person"]
      @article.name.name_content.should == ["Describes a person"]
      #@article.name.retrieve_addressed_node([:name, :name_content]).should == '//one/two'
    end

    it "should not find elements that don't  exist" do
      lambda {@article.name.hedgehog}.should raise_exception NoMethodError
    end

    it "should allow you to call methods on the return value" do
      @article.name.name_content.first.should == "Describes a person"
    end

    it "Should work with proxies" do
      @article.title.should == ["ARTICLE TITLE HYDRANGEA ARTICLE 1", "Artikkelin otsikko Hydrangea artiklan 1", "TITLE OF HOST JOURNAL"]
      ### TODO WHY ARE WE FAILING ON THIS NEXT LINE. HAS NOTHING TO DO WITH DYNAMIC NODES
      @article.term_values(:title,:main_title_lang).should == ['eng']
      @article.title.main_title_lang.should == ['eng']
    end

    it "Should be addressable as an array" do
      @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>{"0"=>"434"} })

      @article.subject.topic[1].to_pointer == [:subject, {:topic => 1}]
      @article.journal[0].issue.length.should == 2
      @article.conference[0].role[1].xpath.should == '//oxns:name[@type="conference"][1]/oxns:role[2]'
      @article.find_by_terms({:journal=>0}, {:issue=>1}, :pages).length.should == 1
      @article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).length.should == 1
      @article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).first.text.should == "434"
      # @article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).first.text.should == "434"
      # @article.find_by_terms({:journal=>0}, {:issue=>1}, :pages, :start).first.text.should == "434"
      ### TODO why doesn't this work?
      @article.term_values(:subject, {:topic => 1}).should == "TOPIC 2"
      @article.subject.topic[1].should == "TOPIC 2"
      #Proxy
      # @article.title[1].to_pointer == [{:title => 1}]
      # @article.title[1].should == "Artikkelin otsikko Hydrangea artiklan 1"
    end
  
  end
end
