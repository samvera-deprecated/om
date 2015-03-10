require 'spec_helper'

describe "an example with :proxy and :ref" do
  before(:all) do
    class ExampleProxyAndRefTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root(:path => "outer", :xmlns => '', :namespace_prefix => nil)
    
        t.resource(:namespace_prefix => nil) {
          t.fedora_pid(:path=>{:attribute=>"objectId"}, :namespace_prefix => nil)
          t.file(:ref=>[:file], :namespace_prefix => nil, :namespace_prefix => nil)
        }
        t.file(:namespace_prefix => nil) {
          t.ds_label(:path=>{:attribute=>"id"}, :namespace_prefix => nil)
          t.size(:path=>{:attribute=>"size"}, :namespace_prefix => nil)
          t.md5(:path=>"checksum", :attributes=>{:type=>"md5"}, :namespace_prefix => nil)
          t.sha1(:path=>"checksum", :attributes=>{:type=>"sha1"}, :namespace_prefix => nil)
        }
        #  really want ead where the type is ead and the file format is XML and the file mimetype is text/xml (and the file id is (?coll_ead.xml ... can be whatever the label of the DS is in the FileAsset object)) 
        t.ead(:ref=>:resource, :attributes=>{:type=>"ead"}) 
        t.image(:ref=>:resource, :attributes=>{:type=>"image"})
    
        t.ead_fedora_pid(:proxy=>[:ead, :fedora_pid])
        t.ead_ds_label(:proxy=>[:ead, :file, :ds_label])
        t.ead_size(:proxy=>[:ead, :file, :size])
        t.ead_md5(:proxy=>[:ead, :file, :md5])
        t.ead_sha1(:proxy=>[:ead, :file, :sha1])
    
        t.image_fedora_pid(:proxy=>[:image, :fedora_pid])
        t.image_ds_label(:proxy=>[:image, :file, :ds_label])
        t.image_size(:proxy=>[:image, :file, :size])
        t.image_md5(:proxy=>[:image, :file, :md5])
        t.image_sha1(:proxy=>[:image, :file, :sha1])
      end
    end
  end

  context 'with empty content' do
    subject { ExampleProxyAndRefTerminology.from_xml "<outer/>" }
    it "should build the parent nodes when setting a proxy term" do
      subject.image_sha1 = '123'
      expect(subject.ng_xml).to be_equivalent_to "<outer><resource type=\"image\"><file><checksum type=\"sha1\">123</checksum></file></resource></outer>"
    end
  end

  context "with existing content" do
    subject do
      ExampleProxyAndRefTerminology.from_xml <<-EOF
  <outer outerId="hypatia:outer" type="outer type">
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

    describe "image" do
      it "should have the right proxy terms" do
        expect(subject.ead_fedora_pid).to include "hypatia:ead_file_asset_fixture"
        expect(subject.ead_ds_label).to include "my_ead.xml"
        expect(subject.ead_size).to include "47570"
        expect(subject.ead_md5).to include "123"
        expect(subject.ead_sha1).to include "456"
      end
    end

    describe "ead" do
      it "should have the right proxy terms" do
        expect(subject.image_fedora_pid).to include "hypatia:coll_img_file_asset_fixture"
        expect(subject.image_ds_label).to include "my_image.jpg"
        expect(subject.image_size).to include "302080"
        expect(subject.image_md5).to include "789"
        expect(subject.image_sha1).to include "666"
      end
    end
  end
end
