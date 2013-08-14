require 'spec_helper'

describe "Inherited terminology" do
  describe "with basic terms" do
    before(:all) do
      class AbstractTerminology
        include OM::XML::Document
        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
          t.foo
        end
      end

      class ConcreteTerminology < AbstractTerminology
        extend_terminology do |t|
          t.bar
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :ConcreteTerminology)
      Object.send(:remove_const, :AbstractTerminology)
    end

    describe "the subclass" do
      subject do
        xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
        ConcreteTerminology.from_xml(xml)
      end

      it "should inherit terminology" do
        subject.foo = "Test value"
        subject.foo.should == ["Test value"]
      end

      it "should have extended terminology" do
        subject.bar = "Test value"
        subject.bar.should == ["Test value"]
      end
    end

    describe "the superclass" do
      subject do
        xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
        AbstractTerminology.from_xml(xml)
      end

      it "should have terminology" do
        subject.foo = "Test value"
        subject.foo.should == ["Test value"]
      end

      it "should not have extended terminology" do
        expect { subject.bar }.to raise_error NoMethodError
      end
    end
  end

  describe "with template terms" do
    before(:all) do
      class AbstractTerminology
        include OM::XML::Document
        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
        end

        define_template :creator do |xml, author, role|
          xml.pbcoreCreator {
            xml.creator(author)
            xml.creatorRole(role, :source=>"PBCore creatorRole") 
          }
        end
      end

      class ConcreteTerminology < AbstractTerminology
      end

      class OtherConcreteTerminology < AbstractTerminology
        define_template :foo do |xml, *args|
          args.each { |arg|
            xml.foo(arg)
          }
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :OtherConcreteTerminology)
      Object.send(:remove_const, :ConcreteTerminology)
      Object.send(:remove_const, :AbstractTerminology)
    end

    describe "on the subclass" do
      subject do
        xml = '<root></root>'
        ConcreteTerminology.from_xml(xml)
      end

      it "should inherit templates" do
        subject.add_child_node subject.ng_xml.root, :creator, 'Test author', 'Primary' 
        subject.ng_xml.xpath('//pbcoreCreator/creatorRole[@source="PBCore creatorRole"]').text.should == "Primary"
      end

      it "should inherit but not extend its parent's templates" do
        OtherConcreteTerminology.template_registry.should have_node_type(:creator)
        OtherConcreteTerminology.template_registry.should have_node_type(:foo)
        AbstractTerminology.template_registry.should_not have_node_type(:foo)
        ConcreteTerminology.template_registry.should_not have_node_type(:foo)
      end
    end
  end
end
