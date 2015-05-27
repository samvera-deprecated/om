# OM (Opinionated Metadata) - Getting Started

OM allows you to define a “terminology” to ease translation between XML
and ruby objects - you can query the xml for Nodes *or* node values
without ever writing a line of XPath.

OM “terms” are ruby symbols you define (in the terminology) that map
specific XML content into ruby object attributes.

The API documentation at [http://rdoc.info/github/projecthydra/om]
provides additional, more targeted information. We will provide links to
the API as appropriate.

## What you will learn from this document

1.  Install OM and run it in IRB
2.  Build an OM Terminology
3.  Use OM XML Document class
4.  Create XML from the OM XML Document
5.  Load existing XML into an OM XML Document
6.  Query OM XML Document to get term values
7.  Access the Terminology of an OM XML Document
8.  Retrieve XPath from the terminology

## Install OM

To get started, you will create a new folder, set up a Gemfile to
install OM, and then run bundler.

```bash
mkdir omtest
cd omtest
```

Using whichever editor you prefer, create a file (in omtest directory)
called Gemfile with the following contents:

```ruby
source 'https://rubygems.org'
gem 'om'
```

Now run bundler to install the gem: (you will need the bundler Gem)

    bundle install

You should now be set to use irb to run the following example.

## Build a simple OM terminology (in irb)

To experiment with abbreviated terminology examples, irb is your friend.
If you are working on a persistent terminology and have to experiment to
make sure you declare your terminology correctly, we recommend writing
test code (e.g. with rspec). You can see examples of this
[here](https://github.com/projecthydra/hydra-tutorial-application/blob/master/spec/models/journal_article_mods_datastream_spec.rb)

```irb
    irb
    require "rubygems"
    => true 
    require "om"
    => true
```

Create a simple (simplish?) Terminology Builder
([OM::XML::Terminology::Builder](OM/XML/Terminology/Builder.html))
based on a couple of elements from the MODS schema.

```ruby
terminology_builder = OM::XML::Terminology::Builder.new do |t|
  t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
  # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
  t.name_ {
    t.namePart
    t.role(:ref=>[:role])
    t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
    t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
    t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
  }

  # Re-use the structure of a :name Term with a different @type attribute
  t.person(:ref=>:name, :attributes=>{:type=>"personal"})
  t.organization(:ref=>:name, :attributes=>{:type=>"corporate"})

  # This is a mods:role, which is used within mods:namePart elements
  t.role {
    t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
    t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
  }
end
```

Now tell the Terminology Builder to build your
[OM::XML::Terminology](OM/XML/Terminology.html):

    terminology = terminology_builder.build

## OM Documents

Generally you will use an [OM::XML::Document](OM/XML/Document.html) to
work with your xml. Here’s how to define a Document class that uses the
same Terminology as above.

In a separate window (so you can keep irb running), create the file
`my_mods_document.rb` in the omtest directory, with this content:

```ruby
class MyModsDocument < ActiveFedora::NokogiriDatastream 
  include OM::XML::Document

  set_terminology do |t|
    t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
    # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
    t.name_ {
      t.namePart
      t.role(:ref=>[:role])
      t.family_name(:path=>"namePart", :attributes=>{:type=>"family"})
      t.given_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
      t.terms_of_address(:path=>"namePart", :attributes=>{:type=>"termsOfAddress"})
    }
    t.person(:ref=>:name, :attributes=>{:type=>"personal"})
    t.organization(:ref=>:name, :attributes=>{:type=>"corporate"})

    # This is a mods:role, which is used within mods:namePart elements
    t.role {
      t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
      t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
    }
  end

  # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
  #  (overrides default behavior of creating a plain xml document)
  def self.xml_template
    # use Nokogiri to build the XML
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.mods(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
         "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
         "xmlns"=>"http://www.loc.gov/mods/v3",
         "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd") {
           xml.titleInfo(:lang=>"") {
             xml.title
           }
           xml.name(:type=>"personal") {
             xml.namePart(:type=>"given")
             xml.namePart(:type=>"family")
             xml.affiliation
             xml.computing_id
             xml.description
             xml.role {
               xml.roleTerm("Author", :authority=>"marcrelator", :type=>"text")
             }
           }
         }
    end
    # return a Nokogiri::XML::Document, not an OM::XML::Document
    return builder.doc
  end
end
```

(Note that we are now also using the ActiveFedora gem.)

[OM::XML::Document](OM/XML/Document.html) provides the `set_terminology`
method to handle the details of creating a TerminologyBuilder and
building the terminology for you. This allows you to focus on defining
the structures of the Terminology itself.

### Creating XML Documents from Scratch using OM

By default, new OM Document instances will create an empty xml document,
but if you override `self.xml_template` to return a different object
(e.g.
[Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html)),
that will be created instead.

In the example above, we have overridden `xml_template` to build an
empty, relatively simple MODS document as a
[Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html).
We use
[Nokogiri::XML::Builder](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Builder.html)
and call its .doc method at the end of xml\_template in order to return
the
[Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html)
object. Instead of using
[Nokogiri::XML::Builder](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Builder.html),
you could put your template into an actual xml file and have
xml\_template use
[Nokogiri::XML::Document.parse](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html#M000225)
to load it. That’s up to you. Create the documents however you want, just return a
[Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html).

To use
[Nokogiri::XML::Builder](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Builder.html)

```
require "my_mods_document"
newdoc = MyModsDocument.new
newdoc.to_xml
=> NoMethodError: undefined method `to_xml' for nil:NilClass
```

### Loading an existing XML document with OM

To load existing XML into your OM Document, use
[#from_xml](OM/XML/Container/ClassMethods.html#from_xml-instance_method")

For an example, download
[hydrangea_article1.xml](https://github.com/projecthydra/om/blob/master/spec/fixtures/mods_articles/hydrangea_article1.xml)
into your working directory (omtest), then run this in irb:

```ruby
sample_xml = File.new("hydrangea_article1.xml")
doc = MyModsDocument.from_xml(sample_xml)
```

Take a look at the document object’s xml that you’ve just populated. We
will use this document for the next few examples.

```ruby
doc.to_xml
```

### Querying OM Documents

Using the Terminology associated with your Document, you can query the
xml for nodes *or* node values without ever writing a line of XPath.

You can use OM::XML::Document.find\_by\_terms to retrieve xml *nodes*
from the datastream. It returns Nokogiri::XML::Node objects:

```ruby
doc.find_by_terms(:person)
doc.find_by_terms(:person).length
doc.find_by_terms(:person).each {|n| puts n.to_xml}
```

You might prefer to use nodes as a way of getting multiple values
pertaining to a node, rather than doing more expensive lookups for each
desired value.

If you want to get directly to the *values* within those nodes, use
`OM::XML::Document.term_values`:

```ruby
doc.term_values(:person, :given_name)
doc.term_values(:person, :family_name)
```

If the xpath points to XML nodes that contain other nodes, the response
to `term_values` will contain `Nokogiri::XML::Node` objects instead of text
values:

```ruby
doc.term_values(:name)
```

For more examples of Querying OM Documents, see [Querying
Documents](https://github.com/projecthydra/om/blob/master/QUERYING_DOCUMENTS.md)

### Updating, Inserting & Deleting Elements (TermValueOperators)

For more examples of Updating OM Documents, see [Updating
Documents](https://github.com/projecthydra/om/blob/master/UPDATING_DOCUMENTS.md)

### Validating Documents

If you have an XML schema defined in your Terminology’s root Term, you
can validate any xml document by calling `.validate` on any instance of
your Document classes.

```ruby
doc.validate
```

**Note:** this method *requires an internet connection*, as it will
download the XML schema from the URL you have specified in the
Terminology’s root term.

### Directly accessing the [Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html) and the [OM::XML::Terminology](https://github.com/projecthydra/om/blob/master/lib/om/xml/terminology.rb)

[OM::XML::Document](https://github.com/projecthydra/om/blob/master/lib/om/xml/document.rb)
is implemented as a container for a
[Nokogiri::XML::Document](http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Document.html).
It uses the associated OM Terminology to provide a bunch of convenience
methods that wrap calls to Nokogiri. If you ever need to operate
directly on the Nokogiri Document, simply call ng\_xml and do what you
need to do. OM will not get in your way.

```ruby
ng_document = doc.ng_xml
```

If you need to look at the Terminology associated with your Document,
call
[#terminology](OM/XML/Document/ClassMethods.html#terminology-instance_method)
on the Document’s *class*.

```ruby
MyModsDocument.terminology
doc.class.terminology
```

### Using a Terminology to generate XPath Queries based on Term Pointers

Because the Terminology is essentially a mapping from XPath queries to
ruby object attributes, in most cases you won’t need to know the actual
XPath queries. Nevertheless, when you *do* want to know the Xpath
(e.g. for ensuring your terminology is correct) for a term, the
Terminology can generate xpath queries based on the structures you’ve
defined ([OM::XML::TermXPathGenerator](OM/XML/TermXpathGenerator.html)).

Here are the xpaths for `:name` and two variants of `:name` that were
created using the `:ref` argument in the Terminology Builder:

```irb
terminology.xpath_for(:name)
=> "//oxns:name"
terminology.xpath_for(:person)
=> "//oxns:name[@type=\"personal\"]" 
terminology.xpath_for(:organization)
=> "//oxns:name[@type=\"corporate\"]"
```

### Solrizing Documents

The solrizer gem provides support for indexing XML documents into Solr
based on OM Terminologies. That process is documented in the [solrizer
documentation](http://rdoc.info/github/projecthydra/solrizer).

