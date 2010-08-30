class OM::XML::Terminology
  class Builder
    
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
      
      @root_term_builders = []
      @cur_term_builder = nil
      
      yield self if block_given?
    end
    
    def method_missing method, *args, &block # :nodoc:
      parent_builder = @cur_term_builder
      @cur_term_builder = OM::XML::Term::Builder.new(method.to_s.sub(/[_!]$/, ''))
      
      # Attach to parent
      if parent_builder
        parent_builder.add_child @cur_term_builder
      else
        @root_term_builders << @cur_term_builder
      end
      
      # Apply options
      opts = args.shift
      @cur_term_builder.settings.merge!(opts) if opts
      
      # Parse children
      yield if block
      
      @cur_term_builder = parent_builder
    end
    
    def build
      terminology = OM::XML::Terminology.new
      @root_term_builders.each do |root_builder|
        terminology.add_term root_builder.build
      end
      terminology
    end
  end
  
  # Terminology Class Definition
  
  attr_accessor :root_terms, :root_term
  
  def initialize
    @root_terms = {}
  end
  
  # Add a term to the root of the terminology
  def add_term(term)
    @root_terms[term.name] = term
  end
  
  def retrieve_term(*args)
    current_term = root_terms[args.delete_at(0)]
    args.each do |arg|
      current_term = current_term.retrieve_child(arg)
    end
    return current_term
  end
  
end
