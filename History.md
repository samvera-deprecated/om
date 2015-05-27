- 2014-09-11: Use HTTPS URLs for RubyGems [Michael Slone]

### 3.1.0 (17 Jul 2014)
- 2014-07-17: Bump solrizer version to \~\> 3.3 [Justin Coyne]
- 2014-07-17: Use the system libxml2 on travis [Justin Coyne]
- 2014-07-17: Remove dependency on mediashelf-loggable [Justin Coyne]
- 2014-06-13: Setting values on a proxy term should build the parent terms if they don’t exist [Justin Coyne]
- 2014-06-05: Handle invalid time for Rails 3 [Justin Coyne]
- 2014-06-02: Updating solrizer, correcting rspec deprecations [Adam Wead]

### 3.0.1 (25 Jun 2013)
- Fix bug where values that were the same as the existing values were removed from the update list

### 3.0.0 (20 Jun 2013)
- Return an array instead of a hash Term\#update\_values
- When passing an array to Term\#update\_values, it will overwrite all of the existing values of that term.
- OM::XML::Document\#find\_by\_terms\_and\_value should match strings with text() = xpath query, rather than contains().

### 2.2.1 (20 Jun 2013)
- Revert deprecation of passing Hash values

### 2.2.0 (20 June 2013)
- Deprecate passing Hash values into DynamicNode\#val= or
- Document\#update\_attributes. This behavior will be removed in 3.0.0
- Rails 4 support
- Pass nil in order to remove a node (instead of blank string)

### 2.1.2 (3 May 2013)
- Fix missing comma after exception

### 2.1.1 (2 May 2013)
- bump solrizer to 3.1.0

### 2.1.0 (29 April 2013)
- support for element names with periods in them
- support for ‘type: :time’

### 2.0.0
- Support new solr schema

### 1.8.0
- Removed unused mods\_article\_terminology.xml
- Replacing :data\_type with :type; deprecating :data\_type
- Making test related to HYDRA-647 pending
- Adding .type method for ruby 1.8.7 compatibility
- XML serialization should use the data\_type node name and not type
- Update homepage in gemspec
- Remove .rvmrc
- Remove debugger from gemfile

### 1.7.0
- Add casting to dates and integers when you specify the :type attribute on a terminology node

### 1.6.1
- Integration spec to illustrate selective querying.
- Add \#use\_terminology and \#extend\_terminology methods to extend existing OM terminologies

### 1.6.0
- Delegate all methods on the dynamic node to the found values
- Allow arrays to be set on dynamic nodes

### 1.5.3
- HYDRA-657 OM Terms that share a name with methods on Nokogiri Builders
have incorrect builder templates
- HYDRA-674 XML Builder templates incorrect for :none attributes

### 1.5.2
- HYDRA-742 Can’t modify frozen string (parameters in rails 3.2, when using ruby 1.9.3)

### 1.5.1
- HYDRA-737 OM tests fail under ree 1.8.7-2011.12 (Fix also applies to ruby 1.8.7-p357)

### 1.5.0
- HYDRA-358 Added support for namespaceless terminologies

### 1.4.4
- HYDRA-415 [https://jira.duraspace.org/browse/HYDRA-415] Fixed insert of attribute nodes
- update to rspec2
- compatibility fixes for ruby 1.9
- RedCloth updated to 4.2.9
- Replace local ‘delimited_list’ logic with `Array#join`

### 1.4.3
- HYDRA-681 https://jira.duraspace.org/browse/HYDRA-681 Om was calling
`.dirty` when updating nodes, it should only do that when it’s operating on a `Nokogiri:Datastream`
- HYDRA-682 https://jira.duraspace.org/browse/HYDRA-682 Om first level terms support update

### 1.4.2
- [HYDRA-667](https://jira.duraspace.org/browse/HYDRA-667) Fixed bug where
updating nodes wasn’t marking the document as dirty

### 1.4.0
- Added dynamic node access DSL. Added a warning when calling an index on a proxy term.

### 1.3.0
- Document automatically includes Validation module, meaning that you can
now call .validate on any document

### 1.2.4
- TerminologyBuilder.root now passes on its options to the root term builder that it creates.

### 1.2.3
- NamedTermProxies can now point to terms at the root of a Terminology

### 1.2.0
- Added OM::XML::TemplateRegistry for built-in templating and creation of new XML nodes

### 1.1.1
- [HYDRA-395](https://jira.duraspace.org/browse/HYDRA-395): Fixed bug that
prevented you from appending term values with apostrophes in them

### 1.1.0
- HYDRA-371: Provide a way to specify a term that points to nodes where an attribute is not set

Add support for this syntax in Terminologies, where an attribute value
can be :none. When an attribute’s value is set to :none, a not()
predicate is used in the resulting xpath

```ruby 
t.computing\_id(:path=\>“namePart”, :attributes=\>{:type=\>:none})
```

will result in an xpath that looks like:

```
//namePart[not(@type)]
namePart[not(@type)]
```

### 1.0.1
- HYDRA-329: Allow for NamedTermProxies at root of Terminology

### 1.0.0
**Stable release**

### 0.1.10
- Improving generation of constrained xpath queries

### 0.1.9
- Improving support for deeply nested nodes (still needs work though)

### 0.1.5
- root\_property now inserts an entry into the properties hash
- added `.generate` method for building new instances of declared properties
- refinements to accessor\_xpath

### 0.1.4
- made attribute\_xpath idempotent

### 0.1.3
- added accessor\_generic\_name and accessor\_hierarchical\_name methods

### 0.1.2
- changed syntax for looking up accessors with (optional) index values
— no using [{:person=\>1}, :first\_name] instead of [:person, 1, :first\_name]

### 0.1.1
- RENAMED to om (formerly opinionated-xml)
- broke up functionality into Modules
- added `OM::XML::Accessor` functionality

### 0.1
- Note: OX v.1 Does not handle treating attribute values as the changing “value” of a node

