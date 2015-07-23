require 'spec_helper'

describe "OM::XML::TermValueOperators" do

  describe "find_by_terms" do
    before(:each) do
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end

    it "should do" do
      expect(@article.find_by_terms({:journal=>0}).length).to eq(1)
    end
  end

  describe "update_values" do
    before(:each) do
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end

    it "should respond with a hash of updated values and their indexes" do
      test_args = {[{"person"=>"0"},"description"]=>{"-1"=>"mork", "1"=>"york"}}
      result = @article.update_values(test_args)
      expect(result).to eq({"person_0_description"=>{"0"=>"mork","1"=>"york"}})
    end

    it "should update the xml in the specified datatsream and save those changes to Fedora" do
      expect(@article.term_values({:person=>0}, :first_name)).to eq(["GIVEN NAMES"])
      test_args = {[{:person=>0}, :first_name]=>{"0"=>"Replacement FirstName"}}
      @article.update_values(test_args)
      expect(@article.term_values({:person=>0}, :first_name)).to eq(["Replacement FirstName"])
      expect(@article).to be_changed
    end

    it "should update the xml according to the find_by_terms_and_values in the given hash" do
      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}}
      result = @article.update_values(terms_update_hash)
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}})

      # Trying again with a more complex update hash
      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, [{:person=>1}, :last_name]=>"Andronicus", [{"person"=>"1"},:first_name]=>["Titus"],[{:person=>1},:role]=>["otherrole1","otherrole2"] }
      result = @article.update_values(terms_update_hash)
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, "person_1_last_name"=>{"0"=>"Andronicus"},"person_1_first_name"=>{"0"=>"Titus"}, "person_1_role"=>{"0"=>"otherrole1","1"=>"otherrole2"}})
      expect(@article).to be_changed
    end

    it "should work when you re-run the command" do
      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}}
      result = @article.update_values(terms_update_hash)
      expect(@article.term_values( {":person"=>"0"}, "affiliation" )).to eq(["affiliation1", "affiliation2", "affiliation3"])
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}})

      # result = @article.update_values(terms_update_hash)
      # result.should == {"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}}
      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}}
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
      result = @article.update_values(terms_update_hash)
      expect(@article.term_values( {":person"=>"0"}, "affiliation" )).to eq(["affiliation1", "affiliation2", "affiliation3"])
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}})
      result = @article.update_values(terms_update_hash)

      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}}
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
      result = @article.update_values(terms_update_hash)
      expect(@article.term_values( {":person"=>"0"}, "affiliation" )).to eq(["affiliation1", "affiliation2", "affiliation3"])
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}})

      # Trying again with a more complex update hash
      terms_update_hash = {[{":person"=>"0"}, "affiliation"]=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, [{:person=>1}, :last_name]=>"Andronicus", [{"person"=>"1"},:first_name]=>["Titus"],[{:person=>1},:role]=>["otherrole1","otherrole2"] }
      result = @article.update_values(terms_update_hash)
      expect(result).to eq({"person_0_affiliation"=>{"0"=>"affiliation1", "1"=>"affiliation2", "2"=>"affiliation3"}, "person_1_last_name"=>{"0"=>"Andronicus"},"person_1_first_name"=>{"0"=>"Titus"}, "person_1_role"=>{"0"=>"otherrole1","1"=>"otherrole2"}})
      expect(@article).to be_changed
    end
  end



end
