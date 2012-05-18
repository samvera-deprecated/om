require 'spec_helper'

describe "element values" do
  before(:all) do
    class ElementValueTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root(:path => "outer", :xmlns => nil)
        t.elementA
        t.elB(:path => "elementB")
        t.elC(:path => "elementC")
      end  
    end
  end

  subject do
    ElementValueTerminology.from_xml <<-EOF
<outer outerId="hypatia:outer" type="outer type">
  <elementA>valA</elementA>
  <elementB>valB1</elementB>
  <elementB animal="vole">valB2</elementB>
  <elementC type="c type" animal="seagull">valC</elementC>
  <resource type="ead" id="coll.ead" objectId="hypatia:ead_file_asset_fixture">
    <file id="my_ead.xml" format="XML" mimetype="text/xml" size="47570">
      <checksum type="md5">123</checksum>
      <checksum type="sha1">456</checksum>
    </file>
  </resource>
  <resource type="image" id="image" objectId="hypatia:coll_img_file_asset_fixture">
    <file id="my_image.jpg" format="JPG" mimetype="image/jpeg" size="302080">
      <checksum type="md5">789</checksum>
      <checksum type="sha1">666</checksum>
    </file>
  </resource>
</outer>
EOF
end

  it "should handle single-element terms correctly" do
    subject.elementA.should == ["valA"]
  end

  it "should handle term paths" do
    subject.elC.should == ["valC"]
  end

  it "should handle multiple-element, terms with paths correctly" do
    subject.elB.should == ["valB1", "valB2"]
  end

end
