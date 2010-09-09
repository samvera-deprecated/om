class OM::XML::Terminology
  
  class BadPointerError < StandardError; end
  class CircularReferenceError < StandardError; end
  
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
        terminology.add_term root_builder.build
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
  
  # Returns the Term corresponding to the given _pointer_.
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
  
  # Return the appropriate xpath query for retrieving nodes corresponding to +term_pointer+ and +query_constraints+
  def xpath_for( term_pointer, query_constraints={}, opts={} )

    if term_pointer.instance_of?(String)
      xpath_query = term_pointer
    else
      term = retrieve_term( *Array(term_pointer) )

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
    end
    return xpath_query
  end
  
  # Returns an array of Terms that have been marked as "root" terms
  def root_terms
    terms.values.select {|term| term.is_root_term? }
  end
  
end
