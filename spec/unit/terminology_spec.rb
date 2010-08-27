require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::Terminology" do
  
    before(:each) do
      @test_builder = OM::XML::Terminology::Builder.new
      @test_terminology = @test_builder.build
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
    
    describe '.builder' do
      it "should return the builder that was used to create the Terminology" do
        @test_terminology.builder.should == @test_builder
      end
      it "should work even if the Terminology was loaded from xml" do
        pending
        vocab = OM::XML::Terminology.from_xml( fixture("sample_mappings.xml") )
        vocab.builder.should be_instance_of OM::XML::Terminology::Builder
      end
    end
    
    describe ".retrieve_mapper" do
      it "should return the mapper identified by the given pointer" do
        mapper = @test_terminology.retrieve_mapper(:name_, :namePart)
        mapper.should == @test_terminology.root_mapper.children[:name_].children[:namePart]
        mapper.should be_instance_of OM::XML::Mapper
        mapper.name.should == :namePart
        mapper.ancestors.length.should == 1
        mapper.ancestors.first.should == @test_terminology.root_mapper.children[:name_]
      end
      it "should raise an informative error if the mapper doesn't exist" do
        pending
        @test_terminology.retrieve_mapper(:nonexistentMapper, :anotherMapperName)
        message.should == "You attempted to retrieve a mapper using this pointer: [:nonexistentMapper, :anotherMapperName] but no mapper exists at that location."
      end
    end
    
    describe ".mapper_xpath" do
      it "should insert calls to xpath array lookup into parent xpaths if parents argument is provided" do    
        pending
        # conference_mapper = TerminologyTest.retrieve_mapper(:conference)
        # role_mapper =  TerminologyTest.retrieve_mapper(:conference, :role)
        # text_mapper = TerminologyTest.retrieve_mapper(:conference, :role, :text)
        TerminologyTest.mapper_xpath({:conference=>0}, {:role=>1}, :text ).should == '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
        # OM::XML::MapperXpathGenerator.expects(:generate_absolute_xpath).with({conference_mapper=>0}, {role_mapper=>1}, text_mapper)
      end
    end
    
    describe ".root_mapper" do
      it "should return a the root mapper for the vocabulary" do
        @test_terminology.mappers.should be_instance_of OM::XML::Mapper
      end
      it "should be private"
    end
  
end