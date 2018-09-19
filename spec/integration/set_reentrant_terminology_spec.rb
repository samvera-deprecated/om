require 'spec_helper'

describe "calling set_terminology more than once" do
  context 'with a Class exposing the #foo accessor' do
    before(:all) do
      class ReentrantTerminology
        include OM::XML::Document

        set_terminology do |t|
          t.root :path => 'root', :xmlns => "asdf"
          t.foo
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :ReentrantTerminology)
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
  end

  describe "after" do
    context 'with a Class exposing the #bar accessor' do
      before(:all) do
        class ReentrantTerminology
          include OM::XML::Document
          set_terminology do |t|
            t.root :path => 'root', :xmlns => "asdf"
            t.bar
          end
        end
      end

      after(:all) do
        Object.send(:remove_const, :ReentrantTerminology)
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
  end

  describe "re-entrant modification" do
    let(:xml) { '<root xmlns="asdf"><foo>fooval</foo><bar>barval</bar></root>' }

    context 'with a Class exposing the #foo accessor' do
      subject(:terminology) { FooReentrantTerminology.from_xml(xml) }

      before(:all) do
        class FooReentrantTerminology
          include OM::XML::Document
          set_terminology do |t|
            t.root :path => 'root', :xmlns => "asdf"
            t.foo
          end
        end
      end

      after(:all) do
        Object.send(:remove_const, :FooReentrantTerminology)
      end

      it "can get foo" do
        expect(terminology.foo).to eq ['fooval']
      end

      context 'with a Class exposing the #bar accessor' do
        subject(:terminology) { BarReentrantTerminology.from_xml(xml) }

        before do
          class BarReentrantTerminology < FooReentrantTerminology
            include OM::XML::Document
            extend_terminology do |t|
              t.bar
            end
          end
        end

        after(:all) do
          Object.send(:remove_const, :BarReentrantTerminology)
        end

        it "can get bar" do
          expect(terminology.bar).to eq ['barval']
        end
      end
    end
  end

  context 'with Classes exposing the #foo and #bar accessors' do
    before(:all) do
      class ReentrantTerminology
        include OM::XML::Document
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

    after(:all) do
      Object.send(:remove_const, :ReentrantTerminology)
      Object.send(:remove_const, :LocalReentrantTerminology)
    end

    describe "subclass modification" do

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
end
