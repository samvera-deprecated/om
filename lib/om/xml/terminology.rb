# When you're defining a Terminology, you will usually use a "Terminology Builder":OM/XML/Terminology/Builder.html to create it
# Each line you put into a "Terminology Builder":OM/XML/Terminology/Builder.html is passed to the constructor for a "Term Builder":OM/XML/Term/Builder.html.
# See the "OM::XML::Term::Builder":OM/XML/Term/Builder.html API docs for complete description of your options for defining each Term.
#
# The most important thing to define in a Terminology is the root term.  This is the place where you set namespaces and schemas for the Terminology
# @example Define a Terminology with a root term "mods", a default namespace of "http://www.loc.gov/mods/v3" and a schema of "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd" (schema is optional)
#   terminology_builder = OM::XML::Terminology::Builder.new do |t|
#     t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
#   end
#   terminology = terminology_builder.build
# If you do not set a namespace, the terminology will assume there is no namespace on the xml document.
class OM::XML::Terminology

  class BadPointerError < StandardError; end
  class CircularReferenceError < StandardError; end

  # Terminology::Builder Class Definition
  #
  # When coding against Builders, remember that they rely on MethodMissing,
  # so any time you call a method on the Builder that it doesn't explicitly recognize,
  # the Builder will add your method & arguments to the it's settings and return itself.
  class Builder

    attr_accessor :schema, :namespaces
    attr_reader :term_builders
    ###
    # Create a new Terminology Builder object.  +options+ are sent to the top level
    # Document that is being built.
    # (not yet supported:) +root+ can be a point in an existing Terminology that you want to add Mappers into
    #
    # Building a document with a particular encoding for example:
    #
    #   Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    #     ...
    #   end
    def initialize(options = {}, root = nil, &block)
      @schema = options.fetch(:schema,nil)
      @namespaces = options.fetch(:namespaces,{})
      @term_builders = {}
      @cur_term_builder = nil

      yield self if block_given?
    end

    # Set the root of the Terminology, along with namespace & schema info
    def root opts, &block
      @schema = opts.fetch(:schema,nil)
      opts.select {|k,v| k.to_s.include?("xmlns")}.each do |ns_pair|
        @namespaces[ns_pair.first.to_s] = ns_pair.last
        if ns_pair.first.to_s == "xmlns"
          @namespaces["oxns"] = ns_pair.last
        end
      end
      root_term_builder = OM::XML::Term::Builder.new(opts.fetch(:path,:root).to_s.sub(/[_!]$/, '')).is_root_term(true)
      term_opts = opts.dup
      term_opts.delete(:schema)
      root_term_builder.settings.merge!(term_opts)
      @term_builders[root_term_builder.name] = root_term_builder

      return root_term_builder
    end

    # Returns an array of Terms that have been marked as "root" terms
    def root_term_builders
      @term_builders.values.select {|term_builder| term_builder.settings[:is_root_term] == true }
    end

    def method_missing method, *args, &block # :nodoc:
      parent_builder = @cur_term_builder
      @cur_term_builder = OM::XML::Term::Builder.new(method.to_s.sub(/[_!]$/, ''), self)

      # Attach to parent
      if parent_builder
        parent_builder.add_child @cur_term_builder
      else
        @term_builders [@cur_term_builder.name] = @cur_term_builder
      end

      # Apply options
      opts = args.shift
      @cur_term_builder.settings.merge!(opts) if opts

      # Parse children
      yield if block

      @cur_term_builder = parent_builder
    end

    # Returns the TermBuilder corresponding to the given _pointer_.
    def retrieve_term_builder(*args)
      args_cp = args.dup
      current_term = @term_builders[args_cp.delete_at(0)]
      if current_term.nil?
        raise OM::XML::Terminology::BadPointerError, "This TerminologyBuilder does not have a root TermBuilder defined that corresponds to \"#{args.first.inspect}\""
      end
      args_cp.each do |arg|
        current_term = current_term.retrieve_child(arg)
        if current_term.nil?
          raise OM::XML::Terminology::BadPointerError, "You attempted to retrieve a TermBuilder using this pointer: #{args.inspect} but no TermBuilder exists at that location. Everything is fine until \"#{arg.inspect}\", which doesn't exist."
        end
      end
      return current_term
    end

    def build
      terminology = OM::XML::Terminology.new(:schema=>@schema, :namespaces=>@namespaces)
      root_term_builders.each do |root_term_builder|
        root_term_builder.children = self.term_builders.dup
        root_term_builder.children.delete(root_term_builder.name)
      end
      @term_builders.each_value do |root_builder|
        terminology.add_term root_builder.build(terminology)
      end
      terminology
    end
  end

  # Terminology Class Definition

  attr_accessor :terms, :schema, :namespaces

  def initialize(options={})
    @schema = options.fetch(:schema,nil)
    @namespaces = options.fetch(:namespaces,{})
    @terms = {}
  end

  # Add a term to the root of the terminology
  def add_term(term)
    @terms[term.name.to_sym] = term
  end

  # Returns true if the current terminology has a term defined at the location indicated by +pointers+ array
  def has_term?(*pointers)
    begin
      retrieve_term(*OM.pointers_to_flat_array(pointers, false))
      return true
    rescue
      return false
    end
  end

  # Returns the Term corresponding to the given _pointer_.
  # Proxies are not expanded
  def retrieve_term(*args)
    args_cp = args.dup
    current_term = terms[args_cp.delete_at(0)]
    if current_term.nil?
      raise OM::XML::Terminology::BadPointerError, "This Terminology does not have a root term defined that corresponds to \"#{args.first.inspect}\""
    else
      args_cp.each do |arg|
        current_term = current_term.retrieve_child(arg)
        if current_term.nil?
          raise OM::XML::Terminology::BadPointerError, "You attempted to retrieve a Term using this pointer: #{args.inspect} but no Term exists at that location. Everything is fine until \"#{arg.inspect}\", which doesn't exist."
        end
      end
    end
    return current_term
  end

  def retrieve_node_subsequent(args, context)
    current_term = context.children[args.shift]
    if current_term.kind_of? OM::XML::NamedTermProxy
      args = (current_term.proxy_pointer + args).flatten
      current_term = context.children[args.shift]
    end
    args.empty? ? current_term : retrieve_node_subsequent(args, current_term)
  end


  ##
  # This is very similar to retrieve_term, however it expands proxy paths out into their cannonical paths
  def retrieve_node(*args)
    current_term = terms[args.shift]
    if current_term.kind_of? OM::XML::NamedTermProxy
      args = (current_term.proxy_pointer + args).flatten
      current_term = terms[args.shift]
    end
    args.empty? ? current_term : retrieve_node_subsequent(args, current_term)
  end


  # Return the appropriate xpath query for retrieving nodes corresponding to the term identified by +pointers+.
  # If the last argument is a String or a Hash, it will be used to add +constraints+ to the resulting xpath query.
  # If you provide an xpath query as the argument, it will be returne untouched.
  def xpath_for(*pointers)
    if pointers.length == 1 && pointers.first.instance_of?(String)
      return pointers.first
    end
    query_constraints = nil

    if pointers.length > 1 && !pointers.last.kind_of?(Symbol)
      query_constraints = pointers.pop
    end

    term = retrieve_node( *pointers )

    if !term.nil?
      if query_constraints.kind_of?(String)
        constraint_value = query_constraints
        xpath_template = term.xpath_constrained
        xpath_query = eval( '"' + xpath_template + '"' )
      elsif query_constraints.kind_of?(Hash) && !query_constraints.empty?
        key_value_pair = query_constraints.first
        constraint_value = key_value_pair.last
        xpath_template = term.children[key_value_pair.first].xpath_constrained
        xpath_query = eval( '"' + xpath_template + '"' )
      else
        xpath_query = term.xpath
      end
    else
      xpath_query = nil
    end
    xpath_query
  end

  # Use the current terminology to generate an xpath with (optional) node indexes for each of the term pointers.
  # Ex.  terminology.xpath_with_indexes({:conference=>0}, {:role=>1}, :text )
  #      will yield an xpath like this: '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
  def xpath_with_indexes(*pointers)
    OM::XML::TermXpathGenerator.generate_xpath_with_indexes(self, *pointers)
  end

  # Retrieves a Term corresponding to +term_pointers+ and return the corresponding xml_builder_template for that term.
  # The resulting xml_builder_template can be passed as a block into Nokogiri::XML::Builder.new
  #
  # +term_pointers+ point to the Term you want to generate a builder template for
  # If the last term_pointer is a String or a Hash, it will be passed into the Term's xml_builder_template method as extra_opts
  # see also: Term.xml_builder_template
  def xml_builder_template(*term_pointers)
    extra_opts = {}

    if term_pointers.length > 1 && !term_pointers.last.kind_of?(Symbol)
      extra_opts = term_pointers.pop
    end

    term = retrieve_term(*term_pointers)
    return term.xml_builder_template(extra_opts)
  end

  # Returns an array of Terms that have been marked as "root" terms
  def root_terms
    terms.values.select {|term| term.is_root_term? }
  end

  # Return an XML representation of the Terminology and its terms
  # @param [Hash] options, the term will be added to it. If :children=>false, skips rendering child Terms
  # @param [Nokogiri::XML::Document] (optional) document to insert the term xml into
  # @return [Nokogiri::XML::Document]
  # @example If :children=>false, skips rendering child Terms
  #   terminology.to_xml(:children=>false)
  # @example You can provide your own Nokogiri document to insert the xml into
  #   doc = Nokogiri::XML::Document.new
  #   terminology.to_xml({}, document=doc)
  def to_xml(options={}, document=Nokogiri::XML::Document.new)
    builder = Nokogiri::XML::Builder.with(document) do |xml|
      xml.terminology {
        xml.schema schema
        xml.namespaces {
          namespaces.each_pair do |ns_name, ns_value|
            xml.namespace {
              xml.name ns_name
              xml.identifier ns_value
            }
          end
        }
        xml.terms
      }
    end
    document = builder.doc
    terms.values.each {|term| term.to_xml(options,document.xpath("//terms").first)}
    return document
  end

  def self.term_generic_name(*pointers)
    pointers_to_flat_array(pointers, false).join("_")
  end

  def self.term_hierarchical_name(*pointers)
    pointers_to_flat_array(pointers, true).join("_")
  end

  def self.pointers_to_flat_array(pointers, include_indices=true)
    OM.pointers_to_flat_array(pointers, include_indices)
  end

end
