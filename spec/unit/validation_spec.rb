require 'spec_helper'

describe "OM::XML::Validation" do
  
  before(:all) do
    class ValidationTest
      include OM::XML::Container
      include OM::XML::Validation
      self.schema_url = "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
    end
  end
  
  before(:each) do
    @sample = ValidationTest.from_xml("<foo><bar>1</bar></foo>")
  end
  
  ## Validation Support 
  # Some of these tests fail when you don't have an internet connection because the mods schema includes other xsd schemas by URL reference.

  describe '#schema_url' do
    it "should allow you to set the schema url" do
      expect(ValidationTest.schema_url).to eq "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"
    end
  end
  
  describe "#schema" do
    it "should return an instance of Nokogiri::XML::Schema loaded from the schema url -- fails if no internet connection" do
      skip "no internet connection"
      expect(ValidationTest.schema).to be_kind_of Nokogiri::XML::Schema
    end
  end

  describe "#validate" do
    it "should validate the provided document against the schema provided in class definition  -- fails if no internet connection" do
      skip "no internet connection"
      expect(ValidationTest.schema).to receive(:validate).with(@sample).and_return([])
      ValidationTest.validate(@sample)
    end
  end

  describe ".validate" do
    it "should rely on class validate method" do
      expect(ValidationTest).to receive(:validate).with(@sample)
      @sample.validate
    end
  end

  describe "#schema_file" do
    before(:all) do
      ValidationTest.schema_file = nil
    end
  
    after(:all) do
      ValidationTest.schema_file = fixture("mods-3-2.xsd")
    end
  
    it "should lazy load the schema file from the @schema_url" do
      expect(ValidationTest.instance_variable_get(:@schema_file)).to be_nil
      expect(ValidationTest).to receive(:file_from_url).with(ValidationTest.schema_url).once.and_return("fake file")
      ValidationTest.schema_file
      expect(ValidationTest.instance_variable_get(:@schema_file)).to eq "fake file"
      expect(ValidationTest.schema_file).to eq "fake file"
    end
  end

  describe "#file_from_url" do
    it "should retrieve a file from the provided url over HTTP" do
      expect(ValidationTest).to receive(:open).with("http://google.com")
      ValidationTest.send(:file_from_url, "http://google.com")
    end
    it "should raise an error if the url is invalid" do
      expect(lambda {ValidationTest.send(:file_from_url, "")}).to raise_error(RuntimeError, /Could not retrieve file from /)
      expect(lambda {ValidationTest.send(:file_from_url, "foo")}).to raise_error(RuntimeError, /Could not retrieve file from foo/)
    end
    it "should raise an error if file retrieval fails" do
      skip "no internet connection"
      expect(lambda {ValidationTest.send(:file_from_url, "http://fedora-commons.org/nonexistent_file")}).to raise_error(RuntimeError, "Could not retrieve file from http://fedora-commons.org/nonexistent_file. Error: 404 Not Found")  
    end
  end
end
