class OM::XML::Terminology
  
  class BadPointerError < StandardError; end
  class CircularReferenceError < StandardError; end
  
  class Builder
    
    attr_accessor :schema, :namespaces
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
      @root_term_builders = {}
      @cur_term_builder = nil
      
      yield self if block_given?
    end
    
    # Set the root of the Terminology, along with namespace & schema info
    def root opts, &block
      @schema = opts.fetch(:schema,nil)
      opts.select {|k,v| k.to_s.include?("xmlns")}.each do |ns_pair|
        @namespaces[ns_pair.first.to_s] = ns_pair.last
      end
      root_term_builder = OM::XML::Term::Builder.new(opts.fetch(:path,:root).to_s.sub(/[_!]$/, '')).is_root_term(true)
      @root_term_builders[root_term_builder.name] = root_term_builder
      
      return root_term_builder
    end
    
    def method_missing method, *args, &block # :nodoc:
      parent_builder = @cur_term_builder
      @cur_term_builder = OM::XML::Term::Builder.new(method.to_s.sub(/[_!]$/, ''), self)
      
      # Attach to parent
      if parent_builder
        parent_builder.add_child @cur_term_builder
      else
        @root_term_builders[@cur_term_builder.name] = @cur_term_builder
      end
      
      # Apply options
      opts = args.shift
      @cur_term_builder.settings.merge!(opts) if opts
      
      # Parse children
      yield if block
      
      @cur_term_builder = parent_builder
    end
    
    def term_builders
      @root_term_builders
    end
    
    # Returns the TermBuilder corresponding to the given _pointer_.
    def retrieve_term_builder(*args)
      args_cp = args.dup
      current_term = @root_term_builders[args_cp.delete_at(0)]
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
      @root_term_builders.each_value do |root_builder|
        terminology.add_term root_builder.build
      end
      terminology
    end
  end
  
  # Terminology Class Definition
  
  attr_accessor :root_terms, :root_term, :schema, :namespaces
  
  def initialize(options={})
    @schema = options.fetch(:schema,nil)
    @namespaces = options.fetch(:namespaces,{})
    @root_terms = {}
  end
  
  # Add a term to the root of the terminology
  def add_term(term)
    @root_terms[term.name.to_sym] = term
  end
  
  # Returns the Term corresponding to the given _pointer_.
  def retrieve_term(*args)
    args_cp = args.dup
    current_term = root_terms[args_cp.delete_at(0)]
    if current_term.nil?
      raise OM::XML::Terminology::BadPointerError, "This Terminology does not have a root term defined that corresponds to \"#{args.first.inspect}\""
    end
    args_cp.each do |arg|
      current_term = current_term.retrieve_child(arg)
      if current_term.nil?
        raise OM::XML::Terminology::BadPointerError, "You attempted to retrieve a Term using this pointer: #{args.inspect} but no Term exists at that location. Everything is fine until \"#{arg.inspect}\", which doesn't exist."
        # raise "This Terminology does not have a term defined that corresponds to \"#{args[0..args.index(arg)].inspect}\""
      end
    end
    return current_term
  end
  
end
