require 'spec_helper'

describe "OM::XML::DynamicNode" do
  describe do
    before do
      class Sample
        include OM::XML::Document

        set_terminology do |t|
          t.root(:path=>"dc", :xmlns=>"http://purl.org/dc/terms/")
          t.creator()
          t.foo()
          t.date_created(:path=>'date.created')
        end

        def self.xml_template
          Nokogiri::XML::Document.parse("<dc xmlns='http://purl.org/dc/terms/' />")
        end

      end
      @sample = Sample.from_xml
    end
    after do
      Object.send(:remove_const, :Sample)
    end

    it "should create templates for dynamic nodes" do
      @sample.creator = "Foo"
      @sample.creator.should == ['Foo']
    end
    it "should create templates for dynamic nodes with multiple values" do
      @sample.creator = ["Foo", "Bar"]
      @sample.creator.should == ['Foo', 'Bar']
    end

    it "should create templates for dynamic nodes with empty string values" do
      @sample.creator = ['']
      @sample.creator.should == ['']
    end

    it "should create templates for plain nodes" do
      @sample.foo = ['in a galaxy far far away']
      @sample.foo.should == ['in a galaxy far far away']
    end

    it "should create templates for dynamic nodes with a period in the element name" do
      @sample.date_created = ['A long time ago']
      @sample.date_created.should == ['A long time ago']
    end

    it "checks inequality" do
      @sample.foo = ['in a galaxy far far away']
      expect(@sample.foo != ['nearby']).to be true
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
        result.length.should == expected_values.length
        expected_values.each {|v| result.should include(v)}
      end

      it "should be able to set first level elements" do
        @article.abstract = "My Abstract"
        @article.abstract.should == ["My Abstract"]
      end

      it "should be able to set first level elements that are arrays" do
        @article.abstract = ["My Abstract", "two"]
        @article.abstract.should == ["My Abstract", 'two']
      end

      it "should delegate all methods (i.e. to_s, first, etc.) to the found array" do
        @article.person.last_name.to_s.should == ["FAMILY NAME", "Gautama"].to_s
        @article.person.last_name.first.should == "FAMILY NAME"
      end

      it "should respond_to? things an array can do" do
        expect(@article.person.last_name).to respond_to(:map)
      end

      it "should delegate with blocks to the found array" do
        arr = []
        @article.person.last_name.each{|x| arr << x}
        arr.should == ["FAMILY NAME", "Gautama"]
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
        @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>"434"})

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
          @article.update_values( {[{:journal=>0}, {:issue=>3}, :pages, :start]=>"434" })
          nodeset = @article.journal(0).issue(1).pages.start.nodeset
          nodeset.should be_kind_of Nokogiri::XML::NodeSet
          nodeset.length.should == @article.journal(0).issue(1).pages.start.length
          nodeset.first.text.should == @article.journal(0).issue(1).pages.start.first
        end
      end

      it "should append nodes at the specified index if possible" do
        @article.journal.title_info = ["all", "for", "the"]
        @article.journal.title_info(3, 'glory')
        @article.term_values(:journal, :title_info).should == ["all", "for", "the", "glory"]
        @article.should be_changed
      end
    
      it "should remove extra nodes if fewer are given than currently exist" do
        @article.journal.title_info = %W(one two three four five)
        @article.journal.title_info = %W(six seven)
        @article.journal.title_info.should == ["six", "seven"]
      end

      describe '==' do
        it "returns true when values of dynamic nodes are equal." do
          @article.name(0).last_name = "Steven"
          @article.name(0).first_name = "Steven"
          (@article.name(0).last_name == @article.name(0).first_name).should == true
        end

        it 'returns false when values of dynamic nodes are not equal.' do
          @article.name(0).first_name = "Horatio"
          @article.name(0).last_name = "Hogginobble"
          (@article.name(0).last_name == @article.name(0).first_name).should == false
        end
      end 
    end
  end
end
