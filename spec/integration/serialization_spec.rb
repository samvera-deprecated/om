require 'spec_helper'

describe "element values" do
  before(:all) do
    class ElementValueTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root(:path => "outer", :xmlns => nil)
        t.my_date(:type=>:date)
        t.my_int(:type=>:integer)
      end
    end
  end

  subject do
    ElementValueTerminology.from_xml <<-EOF
<outer outerId="hypatia:outer" type="outer type">
  <my_date>2012-10-30</my_date>
  <my_int>7</my_int>
</outer>
EOF
end

  describe "Reading from xml" do
    it "should handle date" do
      subject.my_date.should == [Date.parse('2012-10-30')]
    end
    it "should handle ints" do
      subject.my_int.should == [7]
    end
  end
  describe "Writing to xml" do
    it "should handle date" do
      subject.my_date = [Date.parse('2012-09-22')]
      subject.to_xml.should be_equivalent_to '<?xml version="1.0"?>
       <outer outerId="hypatia:outer" type="outer type">
         <my_date>2012-09-22</my_date>
         <my_int>7</my_int>
       </outer>'
    end
    it "should handle ints" do
      subject.my_int = [9]
      subject.to_xml.should be_equivalent_to '<?xml version="1.0"?>
       <outer outerId="hypatia:outer" type="outer type">
         <my_date>2012-10-30</my_date>
         <my_int>9</my_int>
       </outer>'
    end
  end

end

