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
      
      @context  = nil
      @arity    = nil
      @ns       = nil
      
      return unless block_given?

      # This is directly copying behavior from Nokogiri 1.4.2
      # If the builder block is not set up to take any inputs, assume that "self" was used to refer to the builder within the block 
      # Otherwise, yield self into the block.
      #
      #
      # ie. this is passing a block that does not take any inputs (block.arity == 0):
      # Builder.new do
      #   self.foo {
      #     self.bar
      #   }
      # end
      #
      # This is passing in a block that takes one input (block.arity == 1):
      # Builder.new do |xml|
      #   xml.foo {
      #     xml.bar
      #   }
      # end
      
      @arity = block.arity
      if @arity <= 0
        @context = eval('self', block.binding)
        instance_eval(&block)
      else
        yield self
      end
      
    end
    
    def method_missing method, *args, &block # :nodoc:
      if @context && @context.respond_to?(method)
        @context.send(method, *args, &block)
      else
        # node = @doc.create_element(method.to_s.sub(/[_!]$/, ''),*args) { |n|
        #   # Set up the namespace
        #   if @ns
        #     n.namespace = @ns
        #     @ns = nil
        #   end
        # }
        insert(node, &block)
      end
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
