require 'spec_helper'

describe "OM::XML::Term::Builder" do
  
  before(:each) do
    @test_terminology_builder = OM::XML::Terminology::Builder.new do |t|
      t.fruit_trees {
        t.citrus(:attributes=>{"citric_acid"=>"true"}, :index_as=>[:facetable]) {
          t.randomness
        }
        t.stone_fruit(:path=>"prunus", :attributes=>{:genus=>"Prunus"}) 
        t.peach(:ref=>[:fruit_trees, :stone_fruit], :attributes=>{:subgenus=>"Amygdalus", :species=>"Prunus persica"})
        t.nectarine(:ref=>[:fruit_trees, :peach], :attributes=>{:cultivar=>"nectarine"})
        t.almond(:ref=>[:fruit_trees, :peach], :attributes=>{:species=>"Prunus dulcis"})
      }
      t.coconut(:ref=>:pineapple)
      t.banana(:ref=>:coconut)
      t.pineapple(:ref=>:banana)
    end
    
    @citrus = @test_terminology_builder.retrieve_term_builder(:fruit_trees, :citrus)
    @stone_fruit = @test_terminology_builder.retrieve_term_builder(:fruit_trees, :stone_fruit)
    @peach = @test_terminology_builder.retrieve_term_builder(:fruit_trees, :peach)
    @nectarine = @test_terminology_builder.retrieve_term_builder(:fruit_trees, :nectarine)
    @almond = @test_terminology_builder.retrieve_term_builder(:fruit_trees, :almond)
    @pineapple = @test_terminology_builder.retrieve_term_builder(:pineapple)
  end
  
  before(:each) do
    @test_builder = OM::XML::Term::Builder.new("term1")
    @test_builder_2 = OM::XML::Term::Builder.new("term2")
  end
  
  describe '#new' do
   it "should set terminology_builder attribute if provided" do
     mock_terminology_builder = double("TerminologyBuilder")
     OM::XML::Term::Builder.new("term1", mock_terminology_builder).terminology_builder.should == mock_terminology_builder
   end
  end
  
  describe "configuration methods" do
    it "should set the corresponding .settings value return the mapping object" do
      [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path].each do |method_name|
        @test_builder.send("#{method_name}=".to_sym, "#{method_name.to_s}foo")
        @test_builder.settings[method_name].should == "#{method_name.to_s}foo"
      end
    end
    # it "should be chainable" do
    #   test_builder = OM::XML::Term::Builder.new("chainableTerm").tap do |t|
    #     t.index_as = [:facetable, :searchable, :sortable, :displayable).required(true).type(:text)  
    #   end
    #   resulting_settings = test_builder.settings
    #   resulting_settings[:index_as].should == [:facetable, :searchable, :sortable, :displayable]
    #   resulting_settings[:required].should == true 
    #   resulting_settings[:type].should == :text
    # end
  end

  describe "settings" do
    describe "defaults" do
      it "should be set" do
        @test_builder.settings[:required].should == false
        @test_builder.settings[:type].should == :string
        @test_builder.settings[:variant_of].should be_nil
        @test_builder.settings[:attributes].should be_nil
        @test_builder.settings[:default_content_path].should be_nil
      end
    end
  end
  
  describe ".add_child" do
    it "should insert the given Term Builder into the current Term Builder's children" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
    end
  end
  describe ".retrieve_child" do
    it "should fetch the child identified by the given name" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.retrieve_child(@test_builder_2.name).should == @test_builder.children[@test_builder_2.name]
    end
  end
  describe ".children" do
    it "should return a hash of Term Builders that are the children of the current object, indexed by name" do
      @test_builder.add_child(@test_builder_2)
      @test_builder.children[@test_builder_2.name].should == @test_builder_2
    end
  end
  
  describe ".build" do
    it "should build a Term with the given settings and generate its xpath values" do
      test_builder = OM::XML::Term::Builder.new("requiredTextFacet").tap do |t|
        t.index_as = [:facetable, :searchable, :sortable, :displayable]
        t.required = true
        t.type = :text
      end
      result = test_builder.build
      result.should be_instance_of OM::XML::Term
      result.index_as.should == [:facetable, :searchable, :sortable, :displayable]
      result.required.should == true 
      result.type.should == :text
      
      result.xpath.should == OM::XML::TermXpathGenerator.generate_absolute_xpath(result)
      result.xpath_constrained.should == OM::XML::TermXpathGenerator.generate_constrained_xpath(result)
      result.xpath_relative.should == OM::XML::TermXpathGenerator.generate_relative_xpath(result)
    end
    it "should create proxy terms if :proxy is set" do
      test_builder = OM::XML::Term::Builder.new("my_proxy").tap do |t|
        t.proxy = [:foo, :bar]
      end
      result = test_builder.build
      result.should be_kind_of OM::XML::NamedTermProxy
    end
    it "should set path to match name if it is empty" do
      @test_builder.settings[:path].should be_nil
      @test_builder.build.path.should == @test_builder.name.to_s
    end
    it "should work recursively, calling .build on any of its children" do
      OM::XML::Term.any_instance.stub(:generate_xpath_queries!)
      built_child1 = OM::XML::Term.new("child1")
      built_child2 = OM::XML::Term.new("child2")

      mock1 = double("Builder1", :build => built_child1 )
      mock2 = double("Builder2", :build => built_child2 )
      mock1.stub(:name).and_return("child1")
      mock2.stub(:name).and_return("child2")

      @test_builder.children = {:mock1=>mock1, :mock2=>mock2}
      result = @test_builder.build
      result.children[:child1].should == built_child1
      result.children[:child2].should == built_child2
      result.children.length.should == 2
    end
  end
  
  describe ".lookup_refs" do
    it "should return an empty array if no refs are declared" do
      @test_builder.lookup_refs.should == []
    end
    it "should should look up the referenced TermBuilder from the terminology_builder" do
       @peach.lookup_refs.should == [@stone_fruit]
    end
    it "should support recursive refs" do
	    @almond.lookup_refs.should == [@peach, @stone_fruit]
	  end
  	it "should raise an error if the TermBuilder does not have a reference to a terminology builder" do
  	  lambda { 
        OM::XML::Term::Builder.new("referrer").tap do |t|
          t.ref="bongos"
          t.lookup_refs 
        end
      }.should raise_error(StandardError,"Cannot perform lookup_ref for the referrer builder.  It doesn't have a reference to any terminology builder")
	  end
    it "should raise an error if the referece points to a nonexistent term builder" do
      tb = OM::XML::Term::Builder.new("mork",@test_terminology_builder).tap do |t|
        t.ref = [:characters, :aliens]
      end
      lambda { tb.lookup_refs }.should raise_error(OM::XML::Terminology::BadPointerError,"This TerminologyBuilder does not have a root TermBuilder defined that corresponds to \":characters\"")
    end
    it "should raise an error with informative error when given circular references" do
      lambda { @pineapple.lookup_refs }.should raise_error(OM::XML::Terminology::CircularReferenceError,"Circular reference in Terminology: :pineapple => :banana => :coconut => :pineapple")
    end
  end
  
  describe ".resolve_refs!" do 
    it "should do nothing if settings don't include a :ref" do
      settings_pre = @test_builder.settings
      children_pre = @test_builder.children

      @test_builder.resolve_refs!
      @test_builder.settings.should == settings_pre
      @test_builder.children.should == children_pre
    end
    it "should should look up the referenced TermBuilder, use its settings and duplicate its children without changing the name" do
      term_builder = OM::XML::Term::Builder.new("orange",@test_terminology_builder).tap do |b|
        b.ref = [:fruit_trees, :citrus]
      end
      term_builder.resolve_refs!
      # Make sure children and settings were copied
      term_builder.settings.should == @citrus.settings.merge(:path=>"citrus")
  	  term_builder.children.should == @citrus.children
  	  
  	  # Make sure name and parent of both the term_builder and its target were left alone
  	  term_builder.name.should == :orange
  	  @citrus.name.should == :citrus
    end
    it "should set path based on the ref's path if set" do
      [@peach,@almond].each { |x| x.resolve_refs! }
      @peach.settings[:path].should == "prunus"
      @almond.settings[:path].should == "prunus"
    end
    it "should set path based on the first ref's name if no path is set" do
      orange_builder = OM::XML::Term::Builder.new("orange",@test_terminology_builder).tap do |b|
        b.ref= [:fruit_trees, :citrus]
      end
      orange_builder.resolve_refs!
      orange_builder.settings[:path].should == "citrus"
    end
    # It should not be a problem if multiple TermBuilders refer to the same child TermBuilder since the parent-child relationship is set up after calling TermBuilder.build 
    it "should result in clean trees of Terms after building" 
    
  	it "should preserve any extra settings specific to this builder (for variant terms)" do
  	  tb = OM::XML::Term::Builder.new("orange",@test_terminology_builder).tap do |b|
        b.ref= [:fruit_trees, :citrus]
        b.attributes = {color: "orange"}
        b.required =true
      end
  	  tb.resolve_refs!
  	  tb.settings.should == {:path=>"citrus", :attributes=>{"citric_acid"=>"true", :color=>"orange"}, :required=>true, :type=>:string, :index_as=>[:facetable]}
	  end
	  it "should aggregate all settings from refs, combining them with a cascading approach" do
	    @almond.resolve_refs!
	    @almond.settings[:attributes].should == {:genus=>"Prunus",:subgenus=>"Amygdalus", :species=>"Prunus dulcis"}
    end
  end
end
