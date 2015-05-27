# Common Patterns You’ll Use with OM

## Common Terminology Patterns

Let’s say we have xml like this:

```text/xml
<outer outerId="hypatia:outer" type="outer type">
  <elementA>valA</elementA>
  <elementB>valB1</elementB>
  <elementB animal="vole">valB2<elementC>
  <elementC type="c type" animal="seagull">valC<elementC>
  <resource type="ead" id="coll.ead" objectId="hypatia:ead_file_asset_fixture">
    <file id="my_ead.xml" format="XML" mimetype="text/xml" size="47570">
      <checksum type="md5">123</checksum>
      <checksum type="sha1">456</checksum>
    </file>
  </resource>
  <resource type="image" id="image" objectId="hypatia:coll_img_file_asset_fixture">
    <file id="my_image.jpg" format="JPG" mimetype="image/jpeg" size="302080">
      <checksum type="md5">789</checksum>
      <checksum type="sha1">666</checksum>
    </file>
  </resource>
</outer>
```

#### element value

We want an OM term for the value of an element.

In the Datastream Model:

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream 
  # OM (Opinionated Metadata) terminology mapping 
  set_terminology do |t|
    t.root(:path => "outer", :xmlns => '', :namespace_prefix => nil)
    t.elementA
    t.elB(:path => "elementB", :namespace_prefix => nil)
    t.elC(:path => "elementC", :namespace_prefix => nil)
  end  
end
```

This results in :elementA having a value of “valA” and :elB having two
values of “valB1” and “valB2”, and :elC having a value of “valC”

#### Element value given a specific attribute value

We want an OM term for the value of an element, but only if the element
has a specific attribute value.

In the Datastream Model:

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream 
  # OM (Opinionated Metadata) terminology mapping 
  set_terminology do |t|
    t.root(:path => "outer", :xmlns => '')
    t.elementC(:attributes=>{:animal=>"seagull"}, :namespace_prefix => nil)
    t.here(:path=>"resource", :attributes=>{:type=>"ead"}, :namespace_prefix => nil)
    t.there(:path=>"resource", :attributes=>{:type=>"nowhere"}, :namespace_prefix => nil)
  end  
end 
```

This results in :elementC having a value of “valC” and :here having a
value of “123 456”, and :there having a value of nil (or is it “”?)

#### element value given absence of a specific attribute

We want an OM term for an element’s value, but only if the element does
not have a specific attribute.

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream 
  # OM (Opinionated Metadata) terminology mapping 
  set_terminology do |t|
    t.root(:path => "outer", :xmlns => '', :namespace_prefix => nil)
    t.elementB(:attributes=>{:animal=>:none}, :namespace_prefix => nil)
    t.no_attrib(:path => "elementB", :attributes=>{:animal=>:none}, :namespace_prefix => nil)
  end  
end 
```

This results in both :elementB and :no\_attib having the single value
“valB1”

#### attribute value

We want an OM term for an attribute value

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream
  # OM (Opinionated Metadata) terminology mapping
  set_terminology do |t|
    t.root(:path => "outer", :xmlns => '', :namespace_prefix => nil)
    t.elementB {
      t.my_attr(:path => {:attribute=>"animal"}, :namespace_prefix => nil)
    }
    t.alternate(:path => "elementB/@animal", :namespace_prefix => nil)
    t.another(:proxy=>[:elementB, :my_attr_])
    t.animal_attrib(:path => {:attribute=>"animal"}, :namespace_prefix => nil)
  end
end
```

This results in :my\_attr, :alternate and :another all having the single
value of “vole”, and :animal\_attrib having the values “vole” and
“seagull”

#### an example with :proxy and :ref

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream 
  # OM (Opinionated Metadata) terminology mapping 
  set_terminology do |t|
    t.root(:path => "outer", :xmlns => '', :namespace_prefix => nil)

    t.resource(:namespace_prefix => nil) {
      t.fedora_pid(:path=>{:attribute=>"objectId"}, :namespace_prefix => nil)
      t.file(:ref=>[:file], :namespace_prefix => nil, :namespace_prefix => nil)
    }
    t.file(:namespace_prefix => nil) {
      t.ds_label(:path=>{:attribute=>"id"}, :namespace_prefix => nil)
      t.size(:path=>{:attribute=>"size"}, :namespace_prefix => nil)
      t.md5(:path=>"checksum", :attributes=>{:type=>"md5"}, :namespace_prefix => nil)
      t.sha1(:path=>"checksum", :attributes=>{:type=>"sha1"}, :namespace_prefix => nil)
    }
    #  really want ead where the type is ead and the file format is XML and the file mimetype is text/xml (and the file id is (?coll_ead.xml ... can be whatever the label of the DS is in the FileAsset object)) 
    t.ead(:ref=>:resource, :attributes=>{:type=>"ead"}) 
    t.image(:ref=>:resource, :attributes=>{:type=>"image"})

    t.ead_fedora_pid(:proxy=>[:ead, :fedora_pid])
    t.ead_ds_label(:proxy=>[:ead, :file, :ds_label])
    t.ead_size(:proxy=>[:ead, :file, :size])
    t.ead_md5(:proxy=>[:ead, :file, :md5])
    t.ead_sha1(:proxy=>[:ead, :file, :sha1])

    t.image_fedora_pid(:proxy=>[:image, :fedora_pid])
    t.image_ds_label(:proxy=>[:image, :file, :ds_label])
    t.image_size(:proxy=>[:image, :file, :size])
    t.image_md5(:proxy=>[:image, :file, :md5])
    t.image_sha1(:proxy=>[:image, :file, :sha1])
  end  
end
```

This results in:
- :ead_fedora_pid has value “hypatia:ead\_file\_asset\_fixture”
- :ead_ds_label has value “my\_ead.xml”
- :ead_size has value “47570”
- :ead_md5 has value “123”
- :ead_sha1 has value “456”
- :image_fedora_pid has value “hypatia:coll_img_file_asset_fixture”
- :image_ds_label has value “my_image.jpg”
- :image_size has value “302080”
- :image_md5 has value “789”
- :image_sha1 has value “666”

#### xpath-y stuff, also using :ref and :proxy and namespaces

Let’s say we have xml like this:

```text/xml
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
```

We want an OM term corresponding to the `<file>` element based on the
value of the `<location>` element. That is, we want to have a :content
term when the value of `<location>` is “content” and an :html term when
the value of `<location>` is “html”.

In the Datastream Model:

```ruby
class ExampleXMLDS < ActiveFedora::NokogiriDatastream 
  # OM (Opinionated Metadata) terminology mapping 
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
  t.html(:ref=>:file, :path=>'resource/file[location="derivative_html"]', :namespace_prefix => nil)

  t.content_location(:proxy=>[:content, :location])
  t.content_filename(:proxy=>[:content, :filename])
  t.content_format(:proxy=>[:content, :format])

  t.html_location(:proxy=>[:html, :location])
  t.html_filename(:proxy=>[:html, :filename])
  t.html_format(:proxy=>[:html, :format])
end
```

Another example from Molly Pickral of UVa:

We want to access just the author and the advisor from the XML below.
The two `<name>` elements must be distinguished by their `<roleTerm>` value,
a grandchild of the `<name>` element.

We want an :author term with value “Mary Pickral”, and an :advisor term
with value “David Jones”.
      
```text/xml
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
```

In the Datastream Model:

```ruby
class ModsThesis < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3"))
    t.person(:path=>"name", :namespace_prefix => nil) {
      t.given(:path=>"namePart", attribtues=>{:type=>"given"})
        t.family(:path=>"namePart", attribtues=>{:type=>"family"})
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
```

This isn’t quite what the doctor ordered, but :author\_given and
:author\_family can be used to get the author name; similarly for
advisor.

And a variant on the previous example using namespace prefixes.

We want to access just the creator and the repository from the XML
below. The two `<name>` elements must be distinguished by their `<roleTerm>`
value, a grandchild of the `<name>` element.

We want a :creator term with value “David Small”, and a :repository term
with value “Graphic Novel Repository”.

Our xml:

```text/xml
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
```

In the Datastream model:

```ruby
class ModsName < ActiveFedora::NokogiriDatastream
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
```

This terminology not only gives the :creator and :repository values as
desired, but also has :person and :corporate terms for more generic
`<name>` xml. The `:person_full` and `:corporate_full` values include the
value of the `<roleTerm>` field, which is undesirable for display, if not
the index.

### Arguments that can be used in the terminology

e.g. :path, :default\_content\_path, :namespace\_prefix …

ok if this is a link to the rdoc that describes ALL of these with

### Reserved method names (ie. id\_, root\_)

Like Nokogiri …

### Namespaces
- oxns
- document namespaces & node namespaces
- *no namespace* (suppressing oxns in xpath queries)

### :ref and :proxy Terms

If needed (as a differentiator) you can use the root element as a member
of the proxy address:

```ruby
t.root(:path=>"mods")
t.titleInfo {
  t.title
} 
This produces a relative xpath: (e.g. //titleInfo/title)
t.title(:proxy=>[:titleInfo, :title])
This produces an absolute query (e.g. /mods/titleInfo/title)
t.title(:proxy=>[:mods, :titleInfo, :title])
```
