require 'spec_helper'

describe "OM::XML::NodeGenerator" do
  
  
  before(:each) do
    @test_mods_term = OM::XML::Term.new(:mods)
    @test_volume_term = OM::XML::Term.new(:volume, :path=>"detail", :attributes=>{:type=>"volume"}, :default_content_path=>"number")
  end
  
  describe '#generate' do
    it "should use the corresponding builder template(s) to generate the node" do
      expect(OM::XML::NodeGenerator.generate(@test_mods_term, "foo").root.to_xml).to eq "<mods>foo</mods>"
      generated_node = OM::XML::NodeGenerator.generate(@test_volume_term, "108", {:attributes=>{"extraAttr"=>"my value"}})
      expect(generated_node.xpath('./detail[@type="volume"][@extraAttr="my value"]').xpath("./number").text).to eq "108"
      # Would be great if we wrote a have_node custom rspec matcher...
      # generated_node.should have_node 'role[@authority="marcrelator"][@type="code"]' do
      #   with_node "roleTerm", "creator"
      # end
    end

    it "should return Nokogiri Documents" do
      expect(OM::XML::NodeGenerator.generate(@test_mods_term, "foo").class).to eq Nokogiri::XML::Document
    end
  end
end
