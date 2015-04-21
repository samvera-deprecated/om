require 'spec_helper'
require 'fixtures/mods_article'

# TODO:  there should be no dependencies on OM in Solrizer
describe OM::XML::TerminologyBasedSolrizer do
  
  before(:all) do
    Samples::ModsArticle.send(:include, OM::XML::TerminologyBasedSolrizer)
  end
  
  before(:each) do
    article_xml = fixture( File.join("mods_articles", "hydrangea_article1.xml") )
    @mods_article = Samples::ModsArticle.from_xml(article_xml)
  end
  
  describe ".to_solr" do
  
    it "should provide .to_solr and return a SolrDocument" do
      expect(@mods_article).to respond_to(:to_solr)
      expect(@mods_article.to_solr).to be_kind_of(Hash)
    end
  
    it "should optionally allow you to provide the Hash to add fields to and return that document when done" do
      doc = Hash.new
      expect(@mods_article.to_solr(doc)).to equal(doc)
    end
  
    it "should iterate through the terminology terms, calling .solrize_term on each and passing in the solr doc" do
      solr_doc = Hash.new
      @mods_article.field_mapper = Solrizer::FieldMapper.new
      Samples::ModsArticle.terminology.terms.each_pair do |k,v|
        next if k == :mods # we don't index the root node
        expect(@mods_article).to receive(:solrize_term).with(v, solr_doc, @mods_article.field_mapper)
      end
      @mods_article.to_solr(solr_doc)
    end
  
    it "should use Solr mappings to generate field names" do
      solr_doc =  @mods_article.to_solr
      expect(solr_doc["abstract"]).to be_nil
      # NOTE:  OM's old default expected stored and indexed;  this is a change.
      expect(solr_doc["abstract_tesim"]).to eq ["ABSTRACT"]
      expect(solr_doc["title_info_1_language_tesim"]).to eq ["finnish"]
      expect(solr_doc["person_1_role_0_text_tesim"]).to eq ["teacher"]
      # No index_as on the code field.
      expect(solr_doc["person_1_role_0_code_tesim"]).to be_nil 
      expect(solr_doc["person_last_name_tesim"].sort).to eq ["FAMILY NAME", "Gautama"]
      expect(solr_doc["topic_tag_tesim"].sort).to eq ["CONTROLLED TERM", "TOPIC 1", "TOPIC 2"]
      # These are a holdover from an old verison of OM
      expect(solr_doc['journal_0_issue_0_publication_date_dtsim']).to eq ["2007-02-01T00:00:00Z"]
    end

  end

  describe ".solrize_term" do
  
    it "should add fields to a solr document for all nodes corresponding to the given term and its children" do
      solr_doc = Hash.new
      result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:title_info), solr_doc)
      expect(result).to be solr_doc
    end

    it "should add multiple fields based on index_as" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = [:searchable, :displayable, :facetable]

      @mods_article.solrize_term(term, fake_solr_doc)
      
      expected_names = ["DR.", "FAMILY NAME", "GIVEN NAMES", "PERSON_ID"]
      %w(_teim _sim).each do |suffix|
        actual_names = fake_solr_doc["name_0_namePart#{suffix}"].sort
        expect(actual_names).to eq expected_names
      end
    end

    it "should add fields based on type using proxy" do
      unless RUBY_VERSION.match("1.8.7")
        solr_doc = Hash.new
        result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:pub_date), solr_doc)
        expect(solr_doc["pub_date_dtsim"]).to eq ["2007-02-01T00:00:00Z"]
      end
    end

    it "should add fields based on type using ref" do
      solr_doc = Hash.new
      result = @mods_article.solrize_term(Samples::ModsArticle.terminology.retrieve_term(:issue_date), solr_doc)
      expect(solr_doc["issue_date_dtsim"]).to eq ["2007-02-15T00:00:00Z"]
    end

    it "shouldn't index terms where index_as is an empty array" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = []

      @mods_article.solrize_term(term, fake_solr_doc)
      expect(fake_solr_doc["name_0_namePart_teim"]).to be_nil
    end

    it "should index terms where index_as is searchable" do
      fake_solr_doc = {}
      term = Samples::ModsArticle.terminology.retrieve_term(:name)
      term.children[:namePart].index_as = [:searchable]

      @mods_article.solrize_term(term, fake_solr_doc)
      
      expect(fake_solr_doc["name_0_namePart_teim"].sort).to eq ["DR.", "FAMILY NAME", "GIVEN NAMES", "PERSON_ID"]
    end
  end
end
