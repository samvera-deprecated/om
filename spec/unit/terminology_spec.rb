require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology" do
  
    before(:each) do
      @test_terminology = OM::XML::Terminology.new

      # @test_root_term = OM::XML::Term.new("name_")
      
      @test_root_term = OM::XML::Term.new(:name_)
      @test_child_term = OM::XML::Term.new(:namePart)
      @test_root_term.add_child @test_child_term
      @test_terminology.add_term(@test_root_term)
      @test_terminology.root_term = @test_root_term
      
    end
    
    describe '#new' do
    end
    
    describe '#from_xml' do
      it "should let you load mappings from an xml file" do
        pending
        vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
        vocab.should be_instance_of OM::XML::Terminology
        vocab.mappers.should == {}
      end
    end
    
    describe '#to_xml' do
      it "should let you serialize mappings to an xml document" do
        pending
        TerminologyTest.to_xml.should == ""
      end
    end
    
    describe ".retrieve_term" do
      it "should return the mapper identified by the given pointer" do
        term = @test_terminology.retrieve_term(:name_, :namePart)
        term.should == @test_terminology.root_terms[:name_].children[:namePart]
        term.should == @test_child_term
      end
      it "should raise an informative error if the mapper doesn't exist" do
        pending
        @test_terminology.retrieve_mapper(:nonexistentTerm, :anotherTermName)
        message.should == "You attempted to retrieve a mapper using this pointer: [:nonexistentTerm, :anotherTermName] but no mapper exists at that location."
      end
    end
    
    describe ".term_xpath" do
      it "should insert calls to xpath array lookup into parent xpaths if parents argument is provided" do    
        pending
        # conference_mapper = TerminologyTest.retrieve_mapper(:conference)
        # role_mapper =  TerminologyTest.retrieve_mapper(:conference, :role)
        # text_mapper = TerminologyTest.retrieve_mapper(:conference, :role, :text)
        TerminologyTest.term_xpath({:conference=>0}, {:role=>1}, :text ).should == '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
        # OM::XML::TermXpathGenerator.expects(:generate_absolute_xpath).with({conference_mapper=>0}, {role_mapper=>1}, text_mapper)
      end
    end
    
    describe ".root_terms" do
      it "should return a hash terms that have been added to the root of the terminology, indexed by term name" do
        @test_terminology.root_terms[:name_].should == @test_root_term
      end 
    end
    
    describe ".root_term" do
      it "should return the root mapper for the vocabulary" do
        @test_terminology.root_term.should == @test_root_term
        # @test_terminology.terms.first.should be_instance_of OM::XML::Term
      end
      it "should be private"
    end
  
end