require 'spec_helper'

describe "calling set_terminology more than once" do

  before(:all) do
    class ReentrantTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root :path => 'root', :xmlns => "asdf"
        t.foo
      end
    end
  end

  describe "before" do

    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      ReentrantTerminology.from_xml(xml)
    end

    it "can get foo" do
      expect(subject.foo).to eq ['fooval']
    end

    it "cannot get bar" do
      expect { subject.bar }.to raise_error NoMethodError
    end

  end

  describe "after" do

    before(:all) do
      class ReentrantTerminology
        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
          t.bar
        end
      end
    end

    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      ReentrantTerminology.from_xml(xml)
    end

    it "cannot get foo" do
      expect { subject.foo }.to raise_error NoMethodError
    end

    it "can now get bar" do
      expect(subject.bar).to eq ['barval']
    end

  end

  describe "re-entrant modification" do


    before(:all) do
      class ReentrantTerminology
        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
          t.foo
        end
      end

      class ReentrantTerminology
        extend_terminology do |t|
          t.bar
        end
      end
    end

    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      ReentrantTerminology.from_xml(xml)
    end

    it "can get foo" do
      expect(subject.foo).to eq ['fooval']
    end

    it "can get bar" do
      expect(subject.bar).to eq ['barval']
    end

  end

  describe "subclass modification" do


    before(:all) do
      class ReentrantTerminology
        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
          t.foo
        end
      end

      class LocalReentrantTerminology 
        include OM::XML::Document
        use_terminology(ReentrantTerminology)
        extend_terminology do |t|
          t.bar
        end
      end
    end

    subject do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      LocalReentrantTerminology.from_xml(xml)
    end

    it "shouldn't bleed up the inheritence stack" do
      xml = '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>'
      t = ReentrantTerminology.from_xml(xml)

      expect { t.bar }.to raise_error NoMethodError
    end

    it "can get foo" do
      expect(subject.foo).to eq ['fooval']
    end

    it "can get bar" do
      expect(subject.bar).to eq ['barval']
    end

  end

end
