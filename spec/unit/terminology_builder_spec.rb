require 'spec_helper'

describe "OM::XML::Terminology::Builder" do
  
    before(:each) do
      @test_builder = OM::XML::Terminology::Builder.new
      
      @builder_with_block = OM::XML::Terminology::Builder.new do |t|
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

        t.title_info(:path=>"titleInfo") {
          t.main_title(:path=>"title", :label=>"title")
          t.language(:path=>{:attribute=>"lang"})
        }          
        # t.title(:path=>"titleInfo", :default_content_path=>"title") {
        #   t.@language(:path=>{:attribute=>"lang"})
        # }            
        # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
        t.name_ {
          # this is a namepart
          t.namePart(:index_as=>[:searchable, :displayable, :facetable, :sortable], :required=>:true, :type=>:string, :label=>"generic name")
          # affiliations are great
          t.affiliation
          t.displayForm
          t.role(:ref=>[:role])
          t.description
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
          t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
          t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
          t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
        }
        # lookup :person, :first_name        
        t.person(:ref=>:name, :attributes=>{:type=>"personal"})

        t.role {
          t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
          t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
        }
        t.journal(:path=>'relatedItem', :attributes=>{:type=>"host"}) {
          t.title_info
          t.origin_info(:path=>"originInfo")
          t.issn(:path=>"identifier", :attributes=>{:type=>"issn"})
          t.issue(:ref=>[:issue])
        }
        t.issue(:path=>"part") {
          t.volume(:path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
          t.level(:path=>"detail", :attributes=>{:type=>"number"}, :default_content_path=>"number")
          t.pages(:path=>"extent", :attributes=>{:unit=>"pages"}) {
            t.start
            t.end
          }
          # t.start_page(:path=>"pages", :attributes=>{:type=>"start"})
          # t.end_page(:path=>"pages", :attributes=>{:type=>"end"})
          # t.start_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start")
          # t.end_page(:path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end")
          t.publication_date(:path=>"date")
          # t.my_absolute_proxy(:proxy_absolute=>[:name, :role]) # this should always point to [:name, :role]
          t.start_page(:proxy=>[:pages, :start])
          t.start_page(:proxy=>[:pages, :end])
        }
      end

      # @test_full_terminology = @builder_with_block.build
      
    end
    
    it "supports proxy terms at the root of the Terminology" do 
      t_builder = OM::XML::Terminology::Builder.new do |t| 
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd") 
        t.title_info(:path=>"titleInfo") { 
          t.main_title(:path=>"title", :label=>"title") 
          t.language(:path=>{:attribute=>"lang"}) 
        } 
        t.title(:proxy=>[:title_info, :main_title], :index_as =>[:facetable, :not_searchable]) 
      end 

      terminology = t_builder.build 
      expect(terminology.retrieve_term(:title)).to be_kind_of OM::XML::NamedTermProxy
      expect(terminology.retrieve_term(:title).index_as).to eq [:facetable, :not_searchable]
      expect(terminology.retrieve_term(:title_info, :main_title).index_as).to eq []
      expect(terminology.xpath_for(:title)).to eq '//oxns:titleInfo/oxns:title'
      expect(terminology.xpath_with_indexes({:title=>0})).to eq "//oxns:titleInfo/oxns:title"
      # @builder_with_block.build.xpath_for_pointer(:issue).should == '//oxns:part'
      # terminology.xpath_for_pointer(:title).should == '//oxns:titleInfo/oxns:title'
    end
    
    describe '#new' do
      it "should return an instance of OM::XML::Terminology::Builder" do
        expect(OM::XML::Terminology::Builder.new).to be_instance_of OM::XML::Terminology::Builder
      end
      it "should process the input block, creating a new Term Builder for each entry and its children" do
        expected_root_terms = [:mods, :title_info, :issue, :person, :name, :journal, :role]
        expected_root_terms.each do |name|
          expect(@builder_with_block.term_builders).to have_key(name)
        end
        
        expect(@builder_with_block.term_builders.length).to eq expected_root_terms.length
        
        expect(@builder_with_block.term_builders[:journal]).to be_instance_of OM::XML::Term::Builder
        expect(@builder_with_block.term_builders[:journal].settings[:path]).to eq "relatedItem"
        expect(@builder_with_block.term_builders[:journal].settings[:attributes]).to eq({:type=>"host"})

        expect(@builder_with_block.term_builders[:journal].children[:issn]).to be_instance_of OM::XML::Term::Builder
        expect(@builder_with_block.term_builders[:journal].children[:issn].settings[:path]).to eq "identifier"
        expect(@builder_with_block.term_builders[:journal].children[:issn].settings[:attributes]).to eq({:type=>"issn"})
      end
      it "should clip the underscore off the end of any Term names" do
        expect(@builder_with_block.term_builders[:name]).to be_instance_of OM::XML::Term::Builder
        expect(@builder_with_block.term_builders[:name].name).to eq :name

        expect(@builder_with_block.term_builders[:name].children[:date]).to be_instance_of OM::XML::Term::Builder
        expect(@builder_with_block.term_builders[:name].children[:date].settings[:path]).to eq "namePart"
        expect(@builder_with_block.term_builders[:name].children[:date].settings[:attributes]).to eq({:type=>"date"})
      end
    end
    
    describe '#from_xml' do
      it "should let you load mappings from an xml file" do
        skip
        vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
        expect(vocab).to be_instance_of OM::XML::Terminology
        expect(vocab.mappers).to eq({})
      end
    end
    
    describe ".retrieve_term_builder" do
      it "should support looking up Term Builders by pointer" do
        expected = @builder_with_block.term_builders[:name].children[:date]
        expect(@builder_with_block.retrieve_term_builder(:name, :date)).to eq expected
      end
    end
    
    describe "build" do
      it "should generate the new Terminology, calling .build on its Term builders"
      it "should resolve :refs" do
        expect(@builder_with_block.retrieve_term_builder(:name, :role).settings[:ref]).to eq [:role]
        expect(@builder_with_block.retrieve_term_builder(:role).children[:text]).to be_instance_of OM::XML::Term::Builder
        
        built_terminology = @builder_with_block.build
        
        expect(built_terminology.retrieve_term(:name, :role, :text)).to be_instance_of OM::XML::Term
        expect(built_terminology.retrieve_term(:name, :role, :text).path).to eq "roleTerm"
        expect(built_terminology.retrieve_term(:name, :role, :text).attributes).to eq({:type=>"text"})
      end
      it "should put copies of the entire terminology under any root terms" do
        expect(@builder_with_block.root_term_builders).to include(@builder_with_block.retrieve_term_builder(:mods))
        
        built_terminology = @builder_with_block.build
        expected_keys = [:title_info, :issue, :person, :name, :journal, :role]
        
        expect(built_terminology.retrieve_term(:mods).children.length).to eq expected_keys.length

        expected_keys.each do |key|
          expect(built_terminology.retrieve_term(:mods).children.keys).to include(key)
        end
        
        expect(built_terminology.retrieve_term(:mods, :name, :role, :text)).to be_instance_of OM::XML::Term
        expect(built_terminology.retrieve_term(:mods, :person, :role, :text)).to be_instance_of OM::XML::Term

      end
    end
    
    describe '.insert_term' do
      it "should create a new OM::XML::Term::Builder and insert it into the class mappings hash" do
        skip
        
        result = @test_builder.insert_mapper(:name_, :namePart).index_as([:facetable, :searchable, :sortable, :displayable]).required(true).type(:text)  
        expect(@test_builder.mapper_builders(:name_, :namePart)).to eq result
        expect(result).to be_instance_of OM::XML::Mapper::Builder
      end
    end
    
    describe ".root" do
      it "should accept options for the root node, such as namespace(s)  and schema and those values should impact the resulting Terminology" do
        root_term_builder = @test_builder.root(:path=>"mods", :xmlns => 'one:two', 'xmlns:foo' => 'bar', :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
        expect(root_term_builder.settings[:is_root_term]).to  be true
        
        expect(@test_builder.schema).to eq "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        expect(@test_builder.namespaces).to eq({ "oxns"=>"one:two", 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' })
        expect(@test_builder.term_builders[:mods]).to eq root_term_builder      
        
        terminology = @test_builder.build
        expect(terminology.schema).to eq "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
        expect(terminology.namespaces).to eq({ "oxns"=>"one:two", 'xmlns' => 'one:two', 'xmlns:foo' => 'bar' })
      end
      it "should create an explicit term correspoinding to the root node and pass any additional settings into that term" do
        @test_builder.root(:path=>"fwoop", :xmlns => 'one:two', 'xmlns:foo' => 'bar', :index_as=>[:not_searchable], :namespace_prefix=>"foox")
        terminology = @test_builder.build
        term = terminology.retrieve_term(:fwoop)
        expect(term).to be_instance_of OM::XML::Term
        expect(term.is_root_term?).to eq true
        expect(term.index_as).to eq [:not_searchable]        
        expect(term.namespace_prefix).to eq "foox"   
      end
      it "should work within a builder block" do
        expect(@builder_with_block.term_builders[:mods].settings[:is_root_term]).to eq true
      end
    end
    
    describe ".root_term_builders" do
      it "should return the terms that have been marked root" do
        expect(@builder_with_block.root_term_builders.length).to eq 1
        expect(@builder_with_block.root_term_builders.first).to eq @builder_with_block.term_builders[:mods]
      end
    end
    
end
