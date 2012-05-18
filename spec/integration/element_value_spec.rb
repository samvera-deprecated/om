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

        t.elementC(:attributes=>{:animal=>"seagull"}, :namespace_prefix => nil)
        t.here(:path=>"resource", :attributes=>{:type=>"ead"}, :namespace_prefix => nil)
        t.there(:path=>"resource", :attributes=>{:type=>"nowhere"}, :namespace_prefix => nil)
        t.elementD(:attributes=>{:animal=>:none}, :namespace_prefix => nil)
        t.no_attrib(:path => "elementB", :attributes=>{:animal=>:none}, :namespace_prefix => nil)

        t.elementB {
          t.my_attr(:path => {:attribute=>"animal"}, :namespace_prefix => nil)
        }
        t.alternate(:path => "elementB/@animal", :namespace_prefix => nil)
        t.another(:proxy=>[:elementB, :my_attr])
        t.animal_attrib(:path => {:attribute=>"animal"}, :namespace_prefix => nil)
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
  <elementD >valD1</elementC>
  <elementD animal="seagull">valD2</elementC>
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

  it "should handle terms that require specific attributes" do
    subject.elementC.should == ["valC"]
  end

  it "should handle" do
    subject.here.length.should == 1
    subject.here.first.split(/\W/).should include('123', '456')
  end

  it "should handle missing terms" do
    subject.there.should be_empty
  end

  it "should handle element  value given the absence of a specific attribute" do
    subject.elementD.should == ["valD1"]
    subject.no_attrib.should == ["valB1"]
  end

  it "should handle OM terms for an attribute value" do
    subject.elementB.my_attr.should == ["vole"]
    subject.alternate.should == ["vole"]
    subject.another.should == ["vole"]
    subject.animal_attrib.should include("vole", "seagull")
  end
end
