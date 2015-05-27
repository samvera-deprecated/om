# Getting Fancy

## Alternative ways to Manipulate Terms, Terminologies and their Builders

There is more than one way to build a terminology.

### OM::XML::Terminology::Builder Block Syntax

The simplest way to create an OM Terminology is to use the
[OM::XML::Terminology::Builder](OM/XML/Terminology/Builder.html) block
syntax.

In the following examples, we will show different ways of building this
Terminology:

```ruby
builder = OM::XML::Terminology::Builder.new do |t|
t.root(:path=>"grants", :xmlns=>"http://yourmediashelf.com/schemas/hydra-dataset/v0", :schema=>"http://example.org/schemas/grants-v1.xsd")
t.grant {
  t.org(:path=>"organization", :attributes=>{:type=>"funder"}) {
    t.name(:index_as=>:searchable)
  }
  t.number
}
end
another_terminology = builder.build
```

### Using [OM::XML::Term](OM/XML/Term.html)::Builders

First, create the Terminology Builder object:

```ruby
terminology_builder = OM::XML::Terminology::Builder.new
```

The .root method handles creating the root term and setting namespaces,
schema, etc. on the Terminology:

```ruby
terminology_builder.root(:path=>"grants", :xmlns=>"http://yourmediashelf.com/schemas/hydra-dataset/v0", :schema=>"http://example.org/schemas/grants-v1.xsd")
```

This sets the namespaces for you and created the “grants” root term:

```ruby
terminology_builder.namespaces
   => {"oxns"=>"http://yourmediashelf.com/schemas/hydra-dataset/v0", "xmlns"=>"http://yourmediashelf.com/schemas/hydra-dataset/v0"}
terminology_builder.term_builders
```

Create Term Builders for each of the Terms:

```ruby
term1_builder      = OM::XML::Term::Builder.new("grant", terminology_builder).path("grant")
subterm1_builder   = OM::XML::Term::Builder.new("org", terminology_builder).attributes(:type=>"funder")
subsubterm_builder = OM::XML::Term::Builder.new("name", terminology_builder).index_as(:searchable)
subterm2_builder   = OM::XML::Term::Builder.new("number", terminology_builder)
```

Assemble the tree of Term builders by adding child builders to their
parents; then add the top level terms to the root term in the
Terminology builder:

```ruby
subterm1_builder.add_child(subsubterm_builder)
term1_builder.add_child(subterm1_builder)
term1_builder.add_child(subterm2_builder)
terminology_builder.term_builders["grant"] = term1_builder
```

Now build the Terminology, which will also call .build on each of the
Term Builders in the tree:

```ruby
built_terminology = terminology_builder.build
```

Test it out:

```ruby
built_terminology.retrieve_term(:grant, :org, :name)
built_terminology.xpath_for(:grant, :org, :name)
built_terminology.root_terms
built_terminology.terms.keys  # This will only return the Terms at the root of the terminology hierarchy
built_terminology.retrieve_term(:grant).children.keys
```

### Creating Terms & Terminologies without any Builders

If you want to manipulate Terms and Terminologies directly rather than
using the Builder classes, you can consume their APIs at any time.

People don’t often do this, but the option is there if you need it.

Create the Terminology, set its namespaces & (optional) schema:
(Note that you have to set the :oxns namespaces to match :xmlns. This is
usually done for you by the Terminology::Builder.root method.)

```ruby
handcrafted_terminology = OM::XML::Terminology.new
handcrafted_terminology.namespaces[:xmlns] = "http://yourmediashelf.com/schemas/hydra-dataset/v0"
handcrafted_terminology.namespaces[:oxns]  = "http://yourmediashelf.com/schemas/hydra-dataset/v0"
handcrafted_terminology.schema = "http://example.org/schemas/grants-v1.xsd"
```

Create the Terms:

```ruby
# Create term1 (the root) and set it as the root term
root_term = OM::XML::Term.new("grants")
root_term.is_root_term = true

# Create term1 (grant) and its subterms
term1 = OM::XML::Term.new("grant")

subterm1 = OM::XML::Term.new("org")
subterm1.path = "organization"
subterm1.attributes = {:type=>"funder"}

subsubterm = OM::XML::Term.new("name")
subsubterm.index_as = :searchable

subterm2 = OM::XML::Term.new("number")
```

Assemble the tree of terms by adding child terms to their parents, then
add those to the Terminology.

```ruby
subterm1.add_child(subsubterm)
term1.add_child(subterm1)
term1.add_child(subterm2)
handcrafted_terminology.add_term(root_term)
handcrafted_terminology.add_term(term1)
```

Generate the xpath queries for each term. This is usually done for you
by the Term Builder.build method:

```ruby
[root_term, term1, subterm1, subsubterm, subterm2].each {|t| t.generate_xpath_queries!}
```

Test it out:

```ruby
handcrafted_terminology.retrieve_term(:grant, :org, :name)
handcrafted_terminology.xpath_for(:grant, :org, :name)
handcrafted_terminology.root_terms
handcrafted_terminology.terms.keys  # This will only return the Terms at the root of the terminology hierarchy
handcrafted_terminology.retrieve_term(:grant).children.keys
```
