require 'spec_helper'

describe "OM::XML::DynamicNode" do
  describe do
    before do
      class Sample
        include OM::XML::Document

        set_terminology do |t|
          t.root(:path=>"dc", :xmlns=>"http://purl.org/dc/terms/")
          t.creator(:xmlns=>"http://www.loc.gov/mods/v3", :namespace_prefix => "dcterms")
        end

        def self.xml_template
          Nokogiri::XML::Document.parse("<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'/>")
        end

      end
      @sample = Sample.from_xml
    end
    after do
      Object.send(:remove_const, :Sample)
    end
    it "should create templates for dynamic nodes" do
      @sample.creator = "Foo"
      expect(@sample.creator).to eq(['Foo'])
    end
    it "should create templates for dynamic nodes with multiple values" do
      @sample.creator = ["Foo", "Bar"]
      expect(@sample.creator).to eq(['Foo', 'Bar'])
    end
  end


  describe "with a template" do
    before(:each) do
      @sample = OM::Samples::ModsArticle.from_xml( fixture( File.join("test_dummy_mods.xml") ) )
      @article = OM::Samples::ModsArticle.from_xml( fixture( File.join("mods_articles","hydrangea_article1.xml") ) )
    end

    describe "dynamically created nodes" do

      it "should return build an array of values from the nodeset corresponding to the given term" do
        expected_values = ["Berners-Lee", "Jobs", "Wozniak", "Klimt"]
        result = @sample.person.last_name
        expect(result.length).to eq(expected_values.length)
        expected_values.each {|v| expect(result).to include(v)}
      end

      it "should be able to set first level elements" do
        @article.abstract = "My Abstract"
        expect(@article.abstract).to eq(["My Abstract"])
      end

      it "should be able to set first level elements that are arrays" do
        @article.abstract = ["My Abstract", "two"]
        expect(@article.abstract).to eq(["My Abstract", 'two'])
      end

      it "should delegate all methods (i.e. to_s, first, etc.) to the found array" do
        expect(@article.person.last_name.to_s).to eq(["FAMILY NAME", "Gautama"].to_s)
        expect(@article.person.last_name.first).to eq("FAMILY NAME")
      end

      it "should delegate with blocks to the found array" do
        arr = []
        @article.person.last_name.each{|x| arr << x}
        expect(arr).to eq(["FAMILY NAME", "Gautama"])
      end


      describe "setting attributes" do
        it "when they exist" do
          @article.title_info(0).main_title.main_title_lang = "ger"
          expect(@article.title_info(0).main_title.main_title_lang).to eq(["ger"])
        end
        it "when they don't exist" do
          title = @article.title_info(0)
          title.language = "rus"
          expect(@article.title_info(0).language).to eq(["rus"])
        end

      end

      it "should find elements two deep" do
        # TODO reimplement so that method_missing with name is only called once.  Create a new method for name.
        expect(@article.name.name_content.val).to eq(["Describes a person"])
        expect(@article.name.name_content).to eq(["Describes a person"])
        expect(@article.name.name_content(0)).to eq(["Describes a person"])
      end

      it "should not find elements that don't  exist" do
        expect {@article.name.hedgehog}.to raise_exception NoMethodError
      end

      it "should allow you to call methods on the return value" do
        expect(@article.name.name_content.first).to eq("Describes a person")
      end

      it "Should work with proxies" do
        expect(@article.title).to eq(["ARTICLE TITLE HYDRANGEA ARTICLE 1", "Artikkelin otsikko Hydrangea artiklan 1", "TITLE OF HOST JOURNAL"])
        expect(@article.title.main_title_lang).to eq(['eng'])
        expect(@article.title(1).to_pointer).to eq([{:title => 1}])
        expect(@article.journal_title.xpath).to eq("//oxns:relatedItem[@type=\"host\"]/oxns:titleInfo/oxns:title")
        expect(@article.journal_title).to eq(["TITLE OF HOST JOURNAL"])
      end

      it "Should be addressable to a specific node" do
        @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>{"0"=>"434"} })

        @article.subject.topic(1).to_pointer == [:subject, {:topic => 1}]
        expect(@article.journal(0).issue.length).to eq(2)
        @article.journal(0).issue(1).pages.to_pointer == [{:journal=>0}, {:issue=>1}, :pages]
        expect(@article.journal(0).issue(1).pages.length).to eq(1)
        expect(@article.journal(0).issue(1).pages.start.length).to eq(1)
        expect(@article.journal(0).issue(1).pages.start.first).to eq("434")
        expect(@article.subject.topic(1)).to eq(["TOPIC 2"])
        expect(@article.subject.topic(1).xpath).to eq("//oxns:subject/oxns:topic[2]")
      end

      describe ".nodeset" do
        it "should return a Nokogiri NodeSet" do
          @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>{"0"=>"434"} })
          nodeset = @article.journal(0).issue(1).pages.start.nodeset
          expect(nodeset).to be_kind_of Nokogiri::XML::NodeSet
          expect(nodeset.length).to eq(@article.journal(0).issue(1).pages.start.length)
          expect(nodeset.first.text).to eq(@article.journal(0).issue(1).pages.start.first)
        end
      end

      it "should append nodes at the specified index if possible, setting dirty to true if the object responds to dirty" do
        # backwards-compatible stuff..
        allow(@article).to receive(:respond_to?).with(any_args).and_call_original
        allow(@article).to receive(:respond_to?).with(:dirty=).and_return(true)
        expect(@article).to receive(:dirty=).with(true).at_least(2).times
        @article.journal.title_info = ["all", "for", "the"]
        @article.journal.title_info(3, 'glory')
        expect(@article.term_values(:journal, :title_info)).to eq(["all", "for", "the", "glory"])
        expect(@article).to be_changed
      end

    end
  end
end
