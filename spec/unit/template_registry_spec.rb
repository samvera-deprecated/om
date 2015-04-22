require 'spec_helper'

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
      expect(RegistryTest.template_registry.node_types).to include(:person)
      expect(RegistryTest.template_registry.node_types).not_to include(:zombie)
    end

    it "should define new templates" do
      expect(RegistryTest.template_registry.node_types).not_to include(:zombie)
      RegistryTest.define_template :zombie do |xml,name|
        xml.monster(:wants => 'braaaaainz') do
          xml.text(name)
        end
      end
      expect(RegistryTest.template_registry.node_types).to include(:zombie)
    end

    it "should instantiate a detached node from a template" do
      node = RegistryTest.template_registry.instantiate(:zombie, 'Zeke')
      expectation = Nokogiri::XML('<monster wants="braaaaainz">Zeke</monster>').root
      expect(node).to be_equivalent_to(expectation)
    end
    
    it "should raise an error when trying to instantiate an unknown node_type" do
      expect { RegistryTest.template_registry.instantiate(:demigod, 'Hercules') }.to raise_error(NameError)
    end
    
    it "should raise an exception if a missing method name doesn't match a node_type" do
      expect { RegistryTest.template_registry.demigod('Hercules') }.to raise_error(NameError)
    end
    
    it "should undefine existing templates" do
      expect(RegistryTest.template_registry.node_types).to include(:zombie)
      RegistryTest.template_registry.undefine :zombie
      expect(RegistryTest.template_registry.node_types).not_to include(:zombie)
    end
    
    it "should complain if the template name isn't a symbol" do
      expect(lambda { RegistryTest.template_registry.define("die!") { |xml| xml.this_never_happened } }).to raise_error(TypeError)
    end
    
    it "should report on whether a given template is defined" do
      expect(RegistryTest.template_registry.has_node_type?(:person)).to eq true
      expect(RegistryTest.template_registry.has_node_type?(:zombie)).to eq false
    end
    
    it "should include defined node_types as method names for introspection" do
      expect(RegistryTest.template_registry.methods).to include('person')
    end
  end
  
  describe "template-based document manipulations" do
    it "should accept a Nokogiri::XML::Node as target" do
      @test_document.template_registry.after(@test_document.ng_xml.root.elements.first, :person, 'Bob', 'Builder')
      expect(@test_document.ng_xml.root.elements.length).to eq 2
    end

    it "should accept a Nokogiri::XML::NodeSet as target" do
      @test_document.template_registry.after(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(@test_document.ng_xml.root.elements.length).to eq 2
    end
    
    it "should instantiate a detached node from a template using the template name as a method" do
      node = RegistryTest.template_registry.person('Odin', 'All-Father')
      expectation = Nokogiri::XML('<person title="All-Father">Odin</person>').root
      expect(node).to be_equivalent_to(expectation)
    end
    
    it "should add_child" do
      return_value = @test_document.template_registry.add_child(@test_document.ng_xml.root, :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 1).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end
    
    it "should add_next_sibling" do
      return_value = @test_document.template_registry.add_next_sibling(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 1).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end

    it "should add_previous_sibling" do
      return_value = @test_document.template_registry.add_previous_sibling(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(return_value).to eq(@test_document.find_by_terms(:person => 0).first)
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:before]).respecting_element_order
    end

    it "should after" do
      return_value = @test_document.template_registry.after(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(return_value).to eq(@test_document.find_by_terms(:person => 0).first)
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end

    it "should before" do
      return_value = @test_document.template_registry.before(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(return_value).to eq(@test_document.find_by_terms(:person => 1).first)
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:before]).respecting_element_order
    end

    it "should replace" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.template_registry.replace(target_node, :person, 'Bob', 'Builder')
      expect(return_value).to eq(@test_document.find_by_terms(:person => 0).first)
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:instead]).respecting_element_order
    end

    it "should swap" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.template_registry.swap(target_node, :person, 'Bob', 'Builder')
      expect(return_value).to eq target_node
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:instead]).respecting_element_order
    end
    
    it "should yield the result if a block is given" do
      target_node = @test_document.find_by_terms(:person => 0).first
      expectation = Nokogiri::XML('<person xmlns="urn:registry-test" title="Actor">Alice</person>').root
      expect(@test_document.template_registry.swap(target_node, :person, 'Bob', 'Builder') { |old_node|
        expect(old_node).to be_equivalent_to(expectation)
        old_node
      }).to be_equivalent_to(expectation)
    end
  end
    
  describe "document-based document manipulations" do
    it "should accept a Nokogiri::XML::Node as target" do
      @test_document.after_node(@test_document.ng_xml.root.elements.first, :person, 'Bob', 'Builder')
      expect(@test_document.ng_xml.root.elements.length).to eq 2
    end

    it "should accept a Nokogiri::XML::NodeSet as target" do
      @test_document.after_node(@test_document.find_by_terms(:person => 0), :person, 'Bob', 'Builder')
      expect(@test_document.ng_xml.root.elements.length).to eq 2
    end
    
    it "should accept a term-pointer array as target" do
      @test_document.after_node([:person => 0], :person, 'Bob', 'Builder')
      expect(@test_document.ng_xml.root.elements.length).to eq 2
    end
    
    it "should instantiate a detached node from a template" do
      node = @test_document.template(:person, 'Odin', 'All-Father')
      expectation = Nokogiri::XML('<person title="All-Father">Odin</person>').root
      expect(node).to be_equivalent_to(expectation)
    end

    it "should add_child_node" do
      return_value = @test_document.add_child_node(@test_document.ng_xml.root, :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 1).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end
    
    it "should add_next_sibling_node" do
      return_value = @test_document.add_next_sibling_node([:person => 0], :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 1).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end

    it "should add_previous_sibling_node" do
      return_value = @test_document.add_previous_sibling_node([:person => 0], :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 0).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:before]).respecting_element_order
    end

    it "should after_node" do
      return_value = @test_document.after_node([:person => 0], :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 0).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:after]).respecting_element_order
    end

    it "should before_node" do
      return_value = @test_document.before_node([:person => 0], :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 1).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:before]).respecting_element_order
    end

    it "should replace_node" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.replace_node(target_node, :person, 'Bob', 'Builder')
      expect(return_value).to eq @test_document.find_by_terms(:person => 0).first
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:instead]).respecting_element_order
    end

    it "should swap_node" do
      target_node = @test_document.find_by_terms(:person => 0).first
      return_value = @test_document.swap_node(target_node, :person, 'Bob', 'Builder')
      expect(return_value).to eq target_node
      expect(@test_document.ng_xml).to be_equivalent_to(@expectations[:instead]).respecting_element_order
    end
  end
  
end
