require 'spec_helper'

describe "updating multiple nodes in a set" do

  before(:all) do
    class SampleTerminology
      include OM::XML::Document

      set_terminology do |t|
        t.root :path => 'root_element', :xmlns => "asdf"
        t.language
        t.books {
          t.script
        }
      end
    end
  end

  subject do
    SampleTerminology.from_xml(
      '<root_element xmlns="asdf">
         <language>tib</language>
         <language>ger</language>
         <language>chi</language>
         <books>
           <script>tib_script</script>
           <script>ger_script</script>
           <script>chi_script</script>
         </books>
      </root_element>')
  end

  it "should set all the nodes to the values specified by the array" do
    subject.language.should == ["tib","ger","chi"]
    subject.books.script.should == ["tib_script","ger_script","chi_script"]
    subject.update_values_from_array([:language] => ['ger'])
    #
    # needs to transform this into
    #
    subject.update_values_from_array([:books, :script] => ['ger_script'])
    #subject.language.should == ["ger"]
  end



end