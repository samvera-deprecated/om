require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"
require 'equivalent-xml'

describe "OM::XML::TemplateRegistry" do

  before(:all) do
    class RegistryTest

      include OM::XML::Document

      set_terminology do |t|
        t.root(:path => "people", :xmlns => 'urn:registry-test')
        t.person {
          t.title(:path => "@title")
        }
      end

      define_template :person do |xml,name,title|
        xml.person(:title => title) do
          xml.text(name)
        end
      end

    end
  end
  
  after(:all) do
    Object.send(:remove_const, :RegistryTest)
  end

  before(:each) do
    @test_document = RegistryTest.from_xml('<people xmlns="urn:registry-test"><person title="Actor">Alice</person></people>')
    @expectations = {
      :before  => %{<people xmlns="urn:registry-test"><person title="Builder">Bob</person><person title="Actor">Alice</person></people>},
      :after   => %{<people xmlns="urn:registry-test"><person title="Actor">Alice</person><person title="Builder">Bob</person></people>},
      :instead => %{<people xmlns="urn:registry-test"><person title="Builder">Bob</person></people>}
    }
  end
  
  describe "template definitions" do
    it "should contain predefined templates" do
      RegistryTest.templates.node_types.should include(:person)
      RegistryTest.templates.node_types.should_not include(:zombie)
    end

    it "should define new templates" do
      RegistryTest.templates.node_types.should_not include(:zombie)
      RegistryTest.define_template :zombie do |xml,name|
        xml.monster(:wants => 'braaaaainz') do
          xml.text(name)
        end
      end
      RegistryTest.templates.node_types.should include(:zombie)
    end

    it "should instantiate a detached node from a template" do
      node = RegistryTest.templates.instantiate(:zombie, 'Zeke')
      expectation = Nokogiri::XML('<monster wants="braaaaainz">Zeke</monster>').root
      EquivalentXml.equivalent?(node, expectation).should == true
    end
    
    it "should undefine existing templates" do
      RegistryTest.templates.node_types.should include(:zombie)
      RegistryTest.templates.undefine :zombie
      RegistryTest.templates.node_types.should_not include(:zombie)
    end
  end
  
  describe "template-based document manipulations" do
    it "should accept a Nokogiri::XML::Node as target" do
      @test_document.templates.after(@test_document.ng_xml.root.elements.first, :person, 'Bob', 'Builder')
      @test_document.ng_xml.root.elements.length.should == 2
    end

    it "should accept a Nokogiri::XML::NodeSet as target" do
      @test_document.templates.after(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      @test_document.ng_xml.root.elements.length.should == 2
    end
    
    it "should add_child" do
      return_value = @test_document.templates.add_child(@test_document.ng_xml.root, :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end
    
    it "should add_next_sibling" do
      return_value = @test_document.templates.add_next_sibling(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end

    it "should add_previous_sibling" do
      return_value = @test_document.templates.add_previous_sibling(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:before], :element_order => true).should == true
    end

    it "should after" do
      return_value = @test_document.templates.after(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end

    it "should before" do
      return_value = @test_document.templates.before(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:before], :element_order => true).should == true
    end

    it "should replace" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.templates.replace(target_node, :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:instead], :element_order => true).should == true
    end

    it "should swap" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.templates.swap(target_node, :person, 'Bob', 'Builder')
      return_value.should == target_node
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:instead], :element_order => true).should == true
    end
  end
    
  describe "document-based document manipulations" do
    it "should accept a Nokogiri::XML::Node as target" do
      @test_document.after_node(@test_document.ng_xml.root.elements.first, :person, 'Bob', 'Builder')
      @test_document.ng_xml.root.elements.length.should == 2
    end

    it "should accept a Nokogiri::XML::NodeSet as target" do
      @test_document.after_node(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      @test_document.ng_xml.root.elements.length.should == 2
    end
    
    it "should accept a term-pointer array as target" do
      @test_document.after_node([:person => 0], :person, 'Bob', 'Builder')
      @test_document.ng_xml.root.elements.length.should == 2
    end
    
    it "should add_child_node" do
      return_value = @test_document.add_child_node(@test_document.ng_xml.root, :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end
    
    it "should add_next_sibling_node" do
      return_value = @test_document.add_next_sibling_node([:person => 0], :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end

    it "should add_previous_sibling_node" do
      return_value = @test_document.add_previous_sibling_node([:person => 0], :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:before], :element_order => true).should == true
    end

    it "should after_node" do
      return_value = @test_document.after_node([:person => 0], :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:after], :element_order => true).should == true
    end

    it "should before_node" do
      return_value = @test_document.before_node([:person => 0], :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 1).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:before], :element_order => true).should == true
    end

    it "should replace_node" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.replace_node(target_node, :person, 'Bob', 'Builder')
      return_value.should == @test_document.find_by_terms(:person => 0).first
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:instead], :element_order => true).should == true
    end

    it "should swap_node" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.swap_node(target_node, :person, 'Bob', 'Builder')
      return_value.should == target_node
      EquivalentXml.equivalent?(@test_document.ng_xml, @expectations[:instead], :element_order => true).should == true
    end
  end
  
end
