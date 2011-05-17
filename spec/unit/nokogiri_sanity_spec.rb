require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::TermValueOperators" do
  
  describe "find_by_terms" do
    before(:each) do
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end
  
    it "should do" do
      @article.find_by_terms({:journal=>0}).length.should == 1
    end
  end
  
  describe "update_values" do
    before(:each) do
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end
  
    it "should respond with a hash of updated values and their indexes" do
      test_args = {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}      
      result = @article.update_values(test_args)
      result.should == {"person_0_description"=>{"0"=>"mork","1"=>"york"}}
    end
    
    it "should update the xml in the specified datatsream and save those changes to Fedora" do
      @article.term_values({:person=>0}, :first_name).should == ["GIVEN NAMES"]
      test_args = {[{:person=>0}, :first_name]=>{"0"=>"Replacement FirstName"}}
      @article.update_values(test_args)
      @article.term_values({:person=>0}, :first_name).should == ["Replacement FirstName"]
    end
  end
  

  
end