module OM
  module XML
    class DynamicNode
      attr_accessor :term, :parent
      def initialize(term, document, parent=nil)
        self.term = term
        @document = document
        self.parent = parent
      end


      def method_missing (name, *args)
        #puts "MethodMissing DN: #{name}"
        #term = @document.class.terminology.retrieve_addressed_node( (to_pointer << name) )
        addressed_node = retrieve_addressed_node( (to_pointer << name) )
        
        if addressed_node.nil?
          val.send(name, *args)
        else 
          OM::XML::DynamicNode.new(name, @document, self)
        end
      end

      def [](n)
        OM::XML::DynamicNode.new(n, @document, self)
      end

      def val 
        @document.term_values( *to_pointer )
      end
      
      def inspect
        val.inspect
      end

      def ==(other)
        val == other
      end

      def eql?(other)
        self == other
      end

      def to_pointer
        #term can either be a pointer or an index
        if (term.kind_of? Fixnum)
          parent.parent.nil? ?  [{parent.term => term}] : parent.parent.to_pointer << {parent.term => term}
        else ### A pointer
          parent.nil? ? [term] : parent.to_pointer << term
        end
      end 

      def xpath
        
      end


      class AddressedNode
        attr_accessor :xpath, :term, :pointer
        def initialize (pointer, xpath, term)
          self.xpath = xpath
          self.term = term
          self.pointer = pointer
        end
      end
     
      ##
      # This is very similar to Terminology#retrieve_term, however it expands proxy paths out into their cannonical paths
      def retrieve_addressed_node(args, parent=nil)
        first = args.shift
        index = nil 
        if first.kind_of? Hash
           (first, index) = first.to_a.first
        end
        pointer = parent ? parent.pointer << first : [first]
        current_term = @document.class.terminology.retrieve_node(*pointer) # need all of the addresses
        return if current_term.nil?
        path = parent.nil? ? '/' : parent.xpath
        if index
          path += '/' + OM::XML::TermXpathGenerator.add_node_index_predicate(current_term.xpath_relative, index)
        else 
          path += '/' + current_term.xpath_relative
        end
        node = AddressedNode.new(pointer, path, current_term)
        if args.empty? 
          node
        else
          retrieve_addressed_node(args, node)
        end
      end


    end
  end
end
