# These tests illustrate how to select nodes based on their position
# within an XML hierarchy and the value of particular attributes.

require 'spec_helper'

describe "Selecting nodes based on (a) position in hierarchy and (b) attributes" do

  before(:all) do

    # Some XML, with various flavors of <note> nodes:
    #   - outer vs inner;
    #   - with vs without an "a" attribute.
    @xml = %Q{
      <root xmlns="foo">
        <note>o1</note>
        <note>o2</note>
        <note a="a">o3a</note>
        <note a="a">o4a</note>
        <inner>
          <note>i1</note>
          <note>i2</note>
          <note a="a">i3a</note>
          <note a="a">i4a</note>
        </inner>
      </root>
    }

    # Our document class and its OM terminology.
    #
    # In order to select only the outer or inner <note> nodes, we must use
    # the :proxy approach shown below; however, that approach does not work
    # with :attributes. Thus, the general strategy here is first to define OM
    # terms for any attibute-based selections we might want, and then to
    # refine those further using :proxy.
    class FooDoc
      include OM::XML::Document

      set_terminology do |t|
        t.root :path => 'root', :xmlns => 'foo'

        # All notes.
        t.note
        t.all_note       :path => 'note'   # Included for symmetry.

        # All notes with and without attributes.
        t.all_note_a     :path => 'note', :attributes => { :a => "a" }
        t.all_note_not_a :path => 'note', :attributes => { :a => :none }

        # All inner notes -- again, with and without attributes.
        t.inner do
          t.note
          t.note_a     :path => 'note', :attributes => { :a => "a" }
          t.note_not_a :path => 'note', :attributes => { :a => :none }
        end

        # Using the terms defined above, we can now define any additional
        # selections we might need.
        t.all_outer_note   :proxy => [:root, :note]
        t.all_inner_note   :proxy => [:root, :inner, :note]
        t.outer_note_a     :proxy => [:root, :all_note_a]
        t.outer_note_not_a :proxy => [:root, :all_note_not_a]
        t.inner_note_a     :proxy => [:root, :inner, :note_a]
        t.inner_note_not_a :proxy => [:root, :inner, :note_not_a]
      end
    end

    # A document instance.
    @doc = FooDoc.from_xml(@xml)
  end


  # Did it work?
  it "should be able to select all types of <note> nodes" do
    tests = [
      # OM term.            Expected result.
      [ 'all_note',         %w(o1 o2 o3a o4a i1 i2 i3a i4a) ],
      [ 'all_note_a',       %w(      o3a o4a       i3a i4a) ],
      [ 'all_note_not_a',   %w(o1 o2         i1 i2        ) ],
      [ 'all_outer_note',   %w(o1 o2 o3a o4a              ) ],
      [ 'all_inner_note',   %w(              i1 i2 i3a i4a) ],
      [ 'outer_note_a',     %w(      o3a o4a              ) ],
      [ 'outer_note_not_a', %w(o1 o2                      ) ],
      [ 'inner_note_a',     %w(                    i3a i4a) ],
      [ 'inner_note_not_a', %w(              i1 i2        ) ],
    ]
    tests.each { |meth, exp| expect(@doc.send(meth)).to eq exp }
  end

end
