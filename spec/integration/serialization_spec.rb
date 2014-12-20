require 'spec_helper'

describe "element values" do
  before(:all) do
    class ElementValueTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root(:path => "outer", :xmlns => nil)
        t.my_date(:type=>:date)
        t.my_time(:type=>:time)
        t.my_int(:type=>:integer)
        t.active(:type=>:boolean)
        t.wrapper do
          t.inner_date(:type=>:date)
        end
      end
    end
  end


  describe "when the xml template has existing values" do
    subject do
      ElementValueTerminology.from_xml <<-EOF
<outer outerId="hypatia:outer" type="outer type">
  <my_date>2012-10-30</my_date>
  <my_time>2012-10-30T12:22:33Z</my_time>
  <my_int>7</my_int>
  <active>true</active>
</outer>
EOF
    end
    describe "reading  values" do
      it "should deserialize date" do
        expect(subject.my_date).to eq([Date.parse('2012-10-30')])
      end
      it "should deserialize time" do
        expect(subject.my_time).to eq([DateTime.parse('2012-10-30T12:22:33Z')])
      end
      it "should deserialize ints" do
        expect(subject.my_int).to eq([7])
      end
      it "should deserialize boolean" do
        expect(subject.active).to eq([true])
      end
    end
    describe "Writing to xml" do
      it "should serialize time" do
        subject.my_time = [DateTime.parse('2011-01-30T03:45:15Z')]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date>2012-10-30</my_date>
           <my_time>2011-01-30T03:45:15Z</my_time>
           <my_int>7</my_int>
           <active>true</active>
         </outer>'
      end
      it "should serialize date" do
        subject.my_date = [Date.parse('2012-09-22')]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date>2012-09-22</my_date>
           <my_time>2012-10-30T12:22:33Z</my_time>
           <my_int>7</my_int>
           <active>true</active>
         </outer>'
      end
      it "should serialize ints" do
        subject.my_int = [9]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date>2012-10-30</my_date>
           <my_time>2012-10-30T12:22:33Z</my_time>
           <my_int>9</my_int>
           <active>true</active>
         </outer>'
      end
      it "should serialize boolean" do
        subject.active = [false]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date>2012-10-30</my_date>
           <my_time>2012-10-30T12:22:33Z</my_time>
           <my_int>7</my_int>
           <active>false</active>
         </outer>'
      end
    end
  end

  describe "when the xml template is empty" do
    subject do
      ElementValueTerminology.from_xml <<-EOF
<outer outerId="hypatia:outer" type="outer type">
  <my_date></my_date>
  <my_int></my_int>
  <active></active>
</outer>
EOF
    end
    describe "reading  values" do
      it "should deserialize date" do
        expect(subject.my_date).to eq([nil])
      end
      it "should deserialize ints" do
        expect(subject.my_int).to eq([nil])
      end
      it "should deserialize bools" do
        expect(subject.active).to eq([false])
      end
    end
    describe "Writing to xml" do
      it "should serialize date" do
        subject.my_date = [Date.parse('2012-09-22')]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date>2012-09-22</my_date>
           <my_int></my_int>
           <active/>
         </outer>'
      end
      it "should serialize ints" do
        subject.my_int = [9]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date></my_date>
           <my_int>9</my_int>
           <active/>
         </outer>'
      end
      it "should serialize booleans" do
        subject.active = [true]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
           <my_date></my_date>
           <my_int></my_int>
           <active>true</active>
         </outer>'
      end
      it "should serialize empty string values" do
        subject.my_int = [nil]
        subject.my_date = [nil]
        subject.active = [nil]
        expect(subject.to_xml).to be_equivalent_to '<?xml version="1.0"?>
         <outer outerId="hypatia:outer" type="outer type">
         </outer>'
      end
    end
  end
end

