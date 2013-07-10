require 'spec_helper'

describe "Inherited terminology" do

  before(:all) do
    class AbstractTerminology
      include OM::XML::Document
      set_terminology do |t|
        t.root :path => 'root', :xmlns => "asdf"
        t.foo
      end
    end

    class ConcreteTerminology < AbstractTerminology
    end
  end

  after(:all) do
    Object.send(:remove_const, :ConcreteTerminology)
    Object.send(:remove_const, :AbstractTerminology)
  end

  describe "on the subclass" do
    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      ConcreteTerminology.from_xml(xml)
    end

    it "should inherit terminology" do
      subject.foo = "Test value"
      subject.foo.should == ["Test value"]
    end
  end

  describe "on the superclass" do
    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      AbstractTerminology.from_xml(xml)
    end

    it "should have terminology" do
      subject.foo = "Test value"
      subject.foo.should == ["Test value"]
    end
  end
end
