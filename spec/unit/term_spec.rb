require 'spec_helper'

describe OM::XML::Term do
  describe "without a type" do
    it "should default to string" do
      OM::XML::Term.new(:test_term).type.should == :string
    end
  end
  describe "when type is specified" do
    it "should accept date" do
      OM::XML::Term.new(:test_term, :type=>:date).type.should == :date
    end
  end

  describe "a big test" do
    before(:each) do
      @test_name_part = OM::XML::Term.new(:namePart, {}).generate_xpath_queries!
      @test_volume = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
      @test_date = OM::XML::Term.new(:namePart, :attributes=>{:type=> "date"})
      @test_person = OM::XML::Term.new(:namePart, :attributes=>{:type=> :none})
      @test_affiliation = OM::XML::Term.new(:affiliation)
      @test_role_code = OM::XML::Term.new(:roleTerm, :attributes=>{:type=>"code"})
      @test_type = OM::XML::Term.new(:class)
    end

    describe '#new' do
      it "should set path from mapper name if no path is provided" do
        @test_name_part.path.should == "namePart"
      end
      it "should populate the xpath values if no options are provided" do
        local_mapping = OM::XML::Term.new(:namePart)
        local_mapping.xpath_relative.should be_nil
        local_mapping.xpath.should be_nil
        local_mapping.xpath_constrained.should be_nil
      end
    end

    describe 'inner_xml' do
      it "should be a kind of Nokogiri::XML::Node" do
        skip
        @test_mapping.inner_xml.should be_kind_of(Nokogiri::XML::Node)
      end
    end

    describe '#from_node' do
      it "should create a mapper from a nokogiri node" do
        skip "probably should do this in the Builder"
        ng_builder = Nokogiri::XML::Builder.new do |xml|
          xml.mapper(:name=>"person", :path=>"name") {
            xml.attribute(:name=>"type", :value=>"personal")
            xml.mapper(:name=>"first_name", :path=>"namePart") {
              xml.attribute(:name=>"type", :value=>"given")
              xml.attribute(:name=>"another_attribute", :value=>"myval")
            }
          }
        end
        # node = Nokogiri::XML::Document.parse( '<mapper name="first_name" path="namePart"><attribute name="type" value="given"/><attribute name="another_attribute" value="myval"/></mapper>' ).root
        node = ng_builder.doc.root
        mapper = OM::XML::Term.from_node(node)
        mapper.name.should == :person
        mapper.path.should == "name"
        mapper.attributes.should == {:type=>"personal"}
        mapper.internal_xml.should == node

        child = mapper.children[:first_name]

        child.name.should == :first_name
        child.path.should == "namePart"
        child.attributes.should == {:type=>"given", :another_attribute=>"myval"}
        child.internal_xml.should == node.xpath("./mapper").first
      end
    end

    describe ".label" do
      it "should default to the mapper name with underscores converted to spaces"
    end

    describe ".retrieve_term" do
      it "should crawl down into mapper children to find the desired term" do
        mock_role = double("mapper", :children =>{:text=>"the target"})
        mock_conference = double("mapper", :children =>{:role=>mock_role})
        @test_name_part.should_receive(:children).and_return({:conference=>mock_conference})
        @test_name_part.retrieve_term(:conference, :role, :text).should == "the target"
      end
      it "should return an empty hash if no term can be found" do
        @test_name_part.retrieve_term(:journal, :issue, :end_page).should == nil
      end
    end

    describe 'inner_xml' do
      it "should be a kind of Nokogiri::XML::Node" do
        skip
        @test_name_part.inner_xml.should be_kind_of(Nokogiri::XML::Node)
      end
    end

    describe "getters/setters" do
      it "should set the corresponding .settings value and return the current value" do
        # :index_as is a special case

        [:path, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |method_name|
          @test_name_part.send((method_name.to_s+"=").to_sym, "#{method_name.to_s}foo")
          @test_name_part.send(method_name).should == "#{method_name.to_s}foo"
        end
      end
    end

    describe "OM terminology should accept a symbol as a value to :index_as" do
      subject {
        class TestTerminology
          include OM::XML::Document
          
          set_terminology do |t|
            t.as_array :index_as => [:not_searchable]
            t.as_symbol :index_as => :not_searchable
          end
        end

      TestTerminology
      }

      it "should accept an array as an :index_as value" do
        subject.terminology.terms[:as_array].index_as.should be_a_kind_of(Array)
        subject.terminology.terms[:as_array].index_as.should == [:not_searchable]
      end
      it "should accept a plain symbol as a value to :index_as" do
        subject.terminology.terms[:as_symbol].index_as.should be_a_kind_of(Array)
        subject.terminology.terms[:as_symbol].index_as.should == [:not_searchable]
      end
    end
    it "should have a .terminology attribute accessor" do
      @test_volume.should respond_to :terminology
      @test_volume.should respond_to :terminology=
    end
    describe ".ancestors" do
      it "should return an array of Terms that are the ancestors of the current object, ordered from the top/root of the hierarchy" do
        @test_volume.set_parent(@test_name_part)
        @test_volume.ancestors.should == [@test_name_part]
      end
    end
    describe ".parent" do
      it "should retrieve the immediate parent of the given object from the ancestors array" do
        @test_name_part.ancestors = ["ancestor1","ancestor2","ancestor3"]
        @test_name_part.parent.should == "ancestor3"
      end
    end
    describe ".children" do
      it "should return a hash of Terms that are the children of the current object, indexed by name" do
        @test_volume.add_child(@test_name_part)
        @test_volume.children[@test_name_part.name].should == @test_name_part
      end
    end
    describe ".retrieve_child" do
      it "should fetch the child identified by the given name" do
        @test_volume.add_child(@test_name_part)
        @test_volume.retrieve_child(@test_name_part.name).should == @test_volume.children[@test_name_part.name]
      end
    end
    describe ".set_parent" do
      it "should insert the mapper into the given parent" do
        @test_name_part.set_parent(@test_volume)
        @test_name_part.ancestors.should include(@test_volume)
        @test_volume.children[@test_name_part.name].should == @test_name_part
      end
    end
    describe ".add_child" do
      it "should insert the given mapper into the current mappers children" do
        @test_volume.add_child(@test_name_part)
        @test_volume.children[@test_name_part.name].should == @test_name_part
        @test_name_part.ancestors.should include(@test_volume)
      end
    end

    describe "generate_xpath_queries!" do
      it "should return the current object" do
        @test_name_part.generate_xpath_queries!.should == @test_name_part
      end
      it "should regenerate the xpath values" do
        @test_volume.xpath_relative.should be_nil
        @test_volume.xpath.should be_nil
        @test_volume.xpath_constrained.should be_nil

        @test_volume.generate_xpath_queries!.should == @test_volume

        @test_volume.xpath_relative.should == 'detail[@type="volume"]'
        @test_volume.xpath.should == '//detail[@type="volume"]'
        @test_volume.xpath_constrained.should == '//detail[@type="volume" and contains(number, "#{constraint_value}")]'.gsub('"', '\"')
      end
      it "should trigger update on any child objects" do
        mock_child = double("child term")
        mock_child.should_receive(:generate_xpath_queries!).exactly(3).times
        @test_name_part.should_receive(:children).and_return({1=>mock_child, 2=>mock_child, 3=>mock_child})
        @test_name_part.generate_xpath_queries!
      end
    end

    describe "#xml_builder_template" do

      it "should generate a template call for passing into the builder block (assumes 'xml' as the argument for the block)" do
        @test_date.xml_builder_template.should == 'xml.namePart( \'#{builder_new_value}\', \'type\'=>\'date\' )'
        @test_person.xml_builder_template.should == 'xml.namePart( \'#{builder_new_value}\' )'
        @test_affiliation.xml_builder_template.should == 'xml.affiliation( \'#{builder_new_value}\' )'
      end

      it "should accept extra options" do
        # Expected marcrelator_role_xml_builder_template.
        # Include both version to handle either ordering of the hash -- a band-aid hack to fix failing test.
        e1 = %q{xml.roleTerm( '#{builder_new_value}', 'type'=>'code', 'authority'=>'marcrelator' )}
        e2 = %q{xml.roleTerm( '#{builder_new_value}', 'authority'=>'marcrelator', 'type'=>'code' )}
        got = @test_role_code.xml_builder_template(:attributes=>{"authority"=>"marcrelator"})
        [e1, e2].should include(got)
      end

      it "should work for namespaced nodes" do
        @ical_date = OM::XML::Term.new(:ical_date, :path=>"ical:date")
        @ical_date.xml_builder_template.should == "xml[\'ical\'].date( '\#{builder_new_value}' )"
        @ical_date = OM::XML::Term.new(:ical_date, :path=>"date", :namespace_prefix=>"ical")
        @ical_date.xml_builder_template.should == "xml[\'ical\'].date( '\#{builder_new_value}' )"
      end

      it "should work for nodes with default_content_path" do
        @test_volume.xml_builder_template.should == "xml.detail( \'type\'=>'volume' ) { xml.number( '\#{builder_new_value}' ) }"
      end

      it "should support terms that are attributes" do
        @type_attribute_term = OM::XML::Term.new(:type_attribute, :path=>{:attribute=>:type})
        @type_attribute_term.xml_builder_template.should == "xml.@type( '\#{builder_new_value}' )"
      end

      it "should support terms with namespaced attributes" do
        @french_title = OM::XML::Term.new(:french_title, :path=>"title", :attributes=>{"xml:lang"=>"fre"})
        @french_title.xml_builder_template.should == "xml.title( '\#{builder_new_value}', 'xml:lang'=>'fre' )"
      end

      it "should support terms that are namespaced attributes" do
        @xml_lang_attribute_term = OM::XML::Term.new(:xml_lang_attribute, :path=>{:attribute=>"xml:lang"})
        @xml_lang_attribute_term.xml_builder_template.should == "xml.@xml:lang( '\#{builder_new_value}' )"
      end
      
      it "should generate a template call for passing into the builder block (assumes 'xml' as the argument for the block) for terms that share a name with an existing method on the builder" do
        @test_type.xml_builder_template.should == 'xml.class_( \'#{builder_new_value}\' )'
      end
    end
  end
end
