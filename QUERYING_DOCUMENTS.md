# Querying OM Documents

This document will help you understand how to access the information
associated with an [OM::XML::Document](OM/XML/Document.html) object. We
will explain some of the methods provided by the
[OM::XML::Document](OM/XML/Document.html) module and its related modules
[OM::XML::TermXPathGenerator](OM/XML/TermXPathGenerator.html) &
[OM::XML::TermValueOperators](OM/XML/TermValueOperators.html)

*Note: In your code, don’t worry about including
`OM::XML::TermXPathGenerator` and `OM::XML::TermValueOperators` into your
classes. `OM::XML::Document` handles that for you.*

### Load the Sample XML and Sample Terminology

These examples use the Document class defined in
[OM::Samples::ModsArticle](https://github.com/projecthydra/om/blob/master/lib/om/samples/mods_article.rb)

Download
[hydrangea\_article1.xml](https://github.com/projecthydra/om/blob/master/spec/fixtures/mods_articles/hydrangea_article1.xml)
(sample xml) into your working directory, then run this in irb:

```ruby
require "om/samples"
sample_xml = File.new("hydrangea_article1.xml")
doc = OM::Samples::ModsArticle.from_xml(sample_xml)
```

## Querying the [OM::XML::Document](OM/XML/Document.html)

The [OM::XML::Terminology](OM/XML/Terminology.html") declared by
[OM::Samples::ModsArticle](https://github.com/projecthydra/om/blob/master/lib/om/samples/mods_article.rb)
maps the defined Terminology structure to xpath queries. It will also run the queries for you in most cases.

#### xpath\_for method of [OM::XML::Terminology](OM/XML/Terminology.html") retrieves xpath expressions for OM terms

The `xpath_for` method retrieves the xpath used by the
[OM::XML::Terminology](OM/XML/Terminology.html")

Examples of xpaths for `:name` and two variants of `:name` that were created
using the `:ref` argument in the Terminology builder:

```ruby
OM::Samples::ModsArticle.terminology.xpath_for(:name)
=> "//oxns:name"
OM::Samples::ModsArticle.terminology.xpath_for(:person)
=> "//oxns:name[@type=\"personal\"]" 
OM::Samples::ModsArticle.terminology.xpath_for(:organization)
=> "//oxns:name[@type=\"corporate\"]"
```

#### Working with Terms

To retrieve the values of xml nodes, use the `term_values` method:

```ruby
doc.term_values(:person, :first_name) 
doc.term_values(:person, :last_name) 
```

The `term_values` method is defined in the
[OM::XML::TermValueOperators](OM/XML/TermValueOperators.html) module,
which is included in [OM::XML::Document](OM/XML/Document.html)

Not that if a term’s xpath mapping points to XML nodes that contain
other nodes, the response to term\_values will be `Nokogiri::XML::Node`
objects instead of text values:

    doc.term_values(:name)

More examples of using term\_values and find\_by\_terms (defined in
[OM::XML::Document](OM/XML/Document.html)):

```ruby
doc.find_by_terms(:organization).to_xml
doc.term_values(:organization, :role)
=> ["\n      Funder\n    "] 
doc.term_values(:organization, :namePart)
=> ["NSF"]
```

To retrieve the values of nested terms, create a sequence of terms, from
outermost to innermost:

```ruby
OM::Samples::ModsArticle.terminology.xpath_for(:journal, :issue, :pages, :start)
=> "//oxns:relatedItem[@type=\"host\"]/oxns:part/oxns:extent[@unit=\"pages\"]/oxns:start" 
doc.term_values(:journal, :issue, :pages, :start)
=> ["195"] 
```

If you get one of the term names wrong in the sequence, OM will tell you
which one is causing problems. See what happens when you put :page
instead of :pages in your argument to term\_values.

```ruby
doc.term_values(:journal, :issue, :page, :start)
 # OM::XML::Terminology::BadPointerError: You attempted to retrieve a Term using this pointer: [:journal, :issue, :page] but no Term exists at that location. Everything is fine until ":page", which doesn't exist.
```

### When XML Elements are Reused in a Document

Another way to put this: the xpath statement for a term can be ambiguous.

In our MODS document, we have two distinct uses of the title XML element:

1. title of the published article,
2. title of the journal it was published in.

How can we distinguish between these two uses?

```ruby
doc.term_values(:title_info, :main_title)
=> ["ARTICLE TITLE", "VARYING FORM OF TITLE", "TITLE OF HOST JOURNAL"] 
doc.term_values(:mods, :title_info, :main_title)
=> ["ARTICLE TITLE", "VARYING FORM OF TITLE"]
OM::Samples::ModsArticle.terminology.xpath_for(:title_info, :main_title)
=> "//oxns:titleInfo/oxns:title" 
```

The solution: include the root node in your term pointer.

```ruby
OM::Samples::ModsArticle.terminology.xpath_for(:mods, :title_info, :main_title)
=> "//oxns:mods/oxns:titleInfo/oxns:title"
doc.term_values(:mods, :title_info, :main_title)
=> ["ARTICLE TITLE", "VARYING FORM OF TITLE"] 
```

We can still access the Journal title by its own pointers:

```ruby
doc.term_values(:journal, :title_info, :main_title)
 => ["TITLE OF HOST JOURNAL"] 
```

### Making life easier with Proxy Terms

If you use a nested term often, you may want to avoid typing the whole
sequence of term names by defining a *proxy* term.

As you can see in
[OM::Samples::ModsArticle](https://github.com/projecthydra/om/blob/master/lib/om/samples/mods_article.rb),
we have defined a few proxy terms for convenience.

```ruby
t.publication_url(:proxy=>[:location,:url])
t.peer_reviewed(:proxy=>[:journal,:origin_info,:issuance], :index_as=>[:facetable])
t.title(:proxy=>[:mods,:title_info, :main_title])
t.journal_title(:proxy=>[:journal, :title_info, :main_title])
```

You can use proxy terms just like any other term when querying the document.
```ruby
OM::Samples::ModsArticle.terminology.xpath_for(:peer_reviewed)
=> "//oxns:relatedItem[@type=\"host\"]/oxns:originInfo/oxns:issuance"
OM::Samples::ModsArticle.terminology.xpath_for(:title)
=> "//oxns:mods/oxns:titleInfo/oxns:title" 
OM::Samples::ModsArticle.terminology.xpath_for(:journal_title)
=> "//oxns:relatedItem[@type=\"host\"]/oxns:titleInfo/oxns:title"
```

