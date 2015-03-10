require 'spec_helper'

describe "an example of xpath-y stuff, also using :proxy and :ref and namespaces" do

  describe "a contrived example" do
    before(:all) do
      class XpathyStuffTerminology
        include OM::XML::Document

        set_terminology do |t|
          t.root(:path=>"contentMetadata", :xmlns => '', :namespace_prefix => nil) 

          t.resource(:namespace_prefix => nil) {
            t.file(:ref=>[:file], :namespace_prefix => nil)
          }

          t.file(:namespace_prefix => nil) {
            t.location(:path=>"location", :namespace_prefix => nil)
            t.filename(:path=>{:attribute=>"id"}, :namespace_prefix => nil)
            t.format(:path=>{:attribute=>"format"}, :namespace_prefix => nil)
          }
          t.content(:ref=>:file, :path=>'resource/file[location="content"]', :namespace_prefix => nil)
          t.html(:ref=>:file, :path=>'resource/file[location="html"]', :namespace_prefix => nil)

          t.content_location(:proxy=>[:content, :location])
          t.content_filename(:proxy=>[:content, :filename])
          t.content_format(:proxy=>[:content, :format])

          t.html_location(:proxy=>[:html, :location])
          t.html_filename(:proxy=>[:html, :filename])
          t.html_format(:proxy=>[:html, :format])

        end
      end
    end

    subject do
      XpathyStuffTerminology.from_xml <<-EOF
<contentMetadata>
   <resource type="file" id="BU3A5" objectId="val2">
    <file id="BURCH1" format="BINARY">
      <location>content</location>
    </file>
    <file id="BURCH1.html" format="HTML">
      <location>html</location>
    </file>
  </resource>
</contentMetadata>

      EOF
    end

    it "should have a content term" do
      expect(subject.content.first).to match /content/
    end

    it "should have an html term" do
      expect(subject.html.first).to match /html/
    end


  end

  describe "an example from MODS" do
    before(:all) do
      class ModsXpathyStuffTerminology 
        include OM::XML::Document

        set_terminology do |t|
          t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3")
          t.person(:path=>"name", :namespace_prefix => nil) {
            t.given(:path=>"namePart", :attributes=>{:type=>"given"})
            t.family(:path=>"namePart", :attributes=>{:type=>"family"})
            t.role(:namespace_prefix => nil) {
              t.text(:path=>"roleTerm", :attributes=>{:type=>"text"})
              t.code(:path=>"roleTerm", :attributes=>{:type=>"code"})
            }
          }
          t.author(:ref=>:person, :path=>'name[./role/roleTerm="aut"]')
          t.advisor(:ref=>:person, :path=>'name[./role/roleTerm="ths"]')

          t.author_given(:proxy=>[:author, :given])
          t.author_family(:proxy=>[:author, :family])
          t.advisor_given(:proxy=>[:advisor, :given])
          t.advisor_family(:proxy=>[:advisor, :family])
        end
      end
    end

    subject do
      ModsXpathyStuffTerminology.from_xml <<-EOF
    <mods xmlns="http://www.loc.gov/mods/v3"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3"
  xsi:schemaLocation="http://www.loc.gov/mods/v3
  http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
     <name type="personal">
         <namePart type="given">Mary</namePart>
         <namePart type="family">Pickral</namePart>
         <affiliation>University of Virginia</affiliation>
         <namePart>mpc3c</namePart>
         <affiliation>University of Virginia Library</affiliation>
         <role>
             <roleTerm authority="marcrelator" type="code">aut</roleTerm>
             <roleTerm authority="marcrelator" type="text">author</roleTerm>
         </role>
     </name>
    <name type="personal">
      <namePart>der5y</namePart>
      <namePart type="given">David</namePart>
      <namePart type="family">Jones</namePart>
      <affiliation>University of Virginia</affiliation>
      <affiliation>Architectural History Dept.</affiliation>
      <role>
           <roleTerm authority="marcrelator" type="code">ths</roleTerm>
           <roleTerm authority="marcrelator" type="text">advisor</roleTerm>
      </role>
    </name>
  </mods>
      EOF
    end

    it "should have the terms :author_given and :author_family to get the author name" do
      skip "This doesn't seem to work?"
      expect(subject.author_given).to include("Mary")
      expect(subject.author_family).to include("Pickral")
    end

    it "should have the terms :advisor_given and :advisor_family to get the advisor name" do
      skip "This doesn't seem to work?"
      expect(subject.advisor_given).to include("David")
      expect(subject.advisor_family).to include("Small")
    end

  end

  describe "more MODS examples, with a given namespace prefix?" do

    before(:all) do
      class ModsXpathyStuffTerminology 
        include OM::XML::Document

        set_terminology do |t|
          t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-3.xsd", :namespace_prefix => "mods")

          t.name_ {
            t.name_part(:path=>"namePart")
            t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
            t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
            t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
            t.role(:ref=>[:role])
          }
          t.role {
            t.role_term_text(:path=>"roleTerm", :attributes=>{:type=>"text"})
          }

          t.person_full(:ref=>:name, :attributes=>{:type=>"personal"}) 
          t.person(:proxy=>[:person_full, :name_part])
          t.creator(:ref=>:person, :path=>'name[mods:role/mods:roleTerm="creator"]', :xmlns=>"http://www.loc.gov/mods/v3", :namespace_prefix => "mods")

          t.corporate_full(:ref=>:name, :attributes=>{:type=>"corporate"})
          t.corporate(:proxy=>[:corporate_full, :name_part])
          t.repository(:ref=>:corporate, :path=>'name[mods:role/mods:roleTerm="repository"]', :xmlns=>"http://www.loc.gov/mods/v3", :namespace_prefix => "mods")
        end
      end
    end

    subject do
      ModsXpathyStuffTerminology.from_xml <<-EOF
<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">

  <mods:name type="personal">
    <mods:namePart>David Small</mods:namePart>
    <mods:role>
      <mods:roleTerm authority="marcrelator" type="text">creator</mods:roleTerm>
    </mods:role>
  </mods:name>
  <mods:name type="corporate">
    <mods:namePart>Graphic Novel Repository</mods:namePart>
    <mods:role>
      <mods:roleTerm authority="local" type="text">repository</mods:roleTerm>
    </mods:role>
  </mods:name>
</mods:mods>
      EOF
    end

    it "should give a creator value" do
      expect(subject.creator).to include "David Small"
    end

    it "should give a repository value" do
      expect(subject.repository).to include "Graphic Novel Repository"
    end

    it "should have a person term 'for more generic xml'" do
      expect(subject.person).to include "David Small"
    end

    it "should have a corporate term 'for more generic xml'" do
      expect(subject.corporate).to include "Graphic Novel Repository"
    end
  end
end

