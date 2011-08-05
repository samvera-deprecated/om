require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::DynamicNode" do
  
  before(:each) do
    @sample = OM::Samples::ModsArticle.from_xml( fixture( File.join("test_dummy_mods.xml") ) )
    @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    @empty_sample = OM::Samples::ModsArticle.from_xml("")
  end
  
  describe "dynamically created nodes" do

    # it "should return build an array of values from the nodeset corresponding to the given term" do
    #   expected_values = ["Berners-Lee", "Jobs", "Wozniak", "Klimt"]
    #   result = @sample.term_values(:person, :last_name)
    #   result.length.should == expected_values.length
    #   expected_values.each {|v| result.should include(v)}
    # end

    it "should find elements two deep" do
      #TODO ensure that method_missing with name is only called once.  Create a new method for name.
      @article.name.name_content.val.should == ["Describes a person"]
      @article.name.name_content.should == ["Describes a person"]
    end

    it "should not find elements that don't  exist" do
      lambda {@article.name.hedgehog}.should raise_exception NoMethodError
    end

    it "should allow you to call methods on the return value" do
      @article.name.name_content.first.should == "Describes a person"
    end
  
  end
end
