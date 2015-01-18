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
    expect(subject.elementA).to eq ["valA"]
  end

  it "should handle term paths" do
    expect(subject.elC).to eq ["valC"]
  end

  it "should handle multiple-element, terms with paths correctly" do
    expect(subject.elB).to eq ["valB1", "valB2"]
  end

  it "should handle terms that require specific attributes" do
    expect(subject.elementC).to eq ["valC"]
  end

  it "should handle" do
    expect(subject.here.length).to eq 1
    expect(subject.here.first.split(/\W/)).to include('123', '456')
  end

  it "should handle missing terms" do
    expect(subject.there).to be_empty
  end

  it "should handle element  value given the absence of a specific attribute" do
    expect(subject.elementD).to eq ["valD1"]
    expect(subject.no_attrib).to eq ["valB1"]
  end

  it "should handle OM terms for an attribute value" do
    expect(subject.elementB.my_attr).to eq ["vole"]
    expect(subject.alternate).to eq ["vole"]
    expect(subject.another).to eq ["vole"]
    expect(subject.animal_attrib).to include("vole", "seagull")
  end
end
