require 'spec_helper'

describe "use the root element as a member of the proxy address" do
  before(:all) do
    class BlahTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root :path => 'root_element', :xmlns => "asdf"
        t.relevant_container do
          t.the_thing_we_want
        end

        t.the_thing_we_want :proxy => [:root_element, :relevant_container, :the_thing_we_want]
      end
    end
  end

  subject do
    BlahTerminology.from_xml('<root_element xmlns="asdf">
                                <arbitrary_container_element>
                                  <relevant_container>
                                    <the_thing_we_want but="not really">1</the_thing_we_want>
                                  </relevant_container>
                                </arbitrary_container_element>
                                <relevant_container>
                                  <the_thing_we_want>2</the_thing_we_want>
                                </relevant_container>
                              </root_element>')
  end

  it "should pull out all occurences of the_thing_we_want in the relevant_container" do
    expect(subject.relevant_container.the_thing_we_want).to eq ["1", "2"]
  end

  it "should only pull out the_thing_we_want at the root level" do
    expect(subject.the_thing_we_want).to eq ["2"]
  end
end
