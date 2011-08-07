module OM
  module XML
    class DynamicNode
      attr_accessor :key, :parent, :addressed_node, :term
      def initialize(key, document, term, parent=nil)  ##TODO a real term object in here would make it easier to lookup
        self.term = term
        self.key = key
        @document = document
        self.parent = parent
      end

      def method_missing (name, *args)
        #Nil term means this is an index accessor
        if /=$/.match(name.to_s)
          new_update_node(name, args)
        else
          child =  term_child_by_name(term.nil? ? parent.term : term, name)
          if child
            OM::XML::DynamicNode.new(name, @document, child, self)
          else 
            val.send(name, *args)
          end
        end
      end

      def new_update_node(name, args)
        modified_name = name.to_s.chop.to_sym
        node = nil
        if modified_name == :[]
          self.val=[{args.shift =>args.first}]
        else  
          child = term.retrieve_term(modified_name)
          node = OM::XML::DynamicNode.new(modified_name, @document, child, self)
          node.val=args
        end
      end


      def val=(args)
        new_values = sanitize_new_values(args.first)
        new_values.each do |y,z|   
## If we pass something that already has an index on it, we should be able to add it.
          if @document.find_by_xpath(xpath)[y.to_i].nil? || y.to_i == -1
            @document.term_values_append(:parent_select=> parent.to_pointer,:parent_index=>0,:template=>to_pointer,:values=>z)
          else
            @document.term_value_update(xpath, y.to_i, z)
          end
        end
      end

      def sanitize_new_values(new_values)
          # Sanitize new_values to always be a hash with indexes
          case new_values
          when Hash
          when Array
            nv = new_values.dup
            new_values = {}
            nv.each {|v| new_values[nv.index(v).to_s] = v}
          else
            new_values = {"0"=>new_values}
          end
          new_values
      end

      def term_child_by_name(term, name)
        if (term.kind_of? NamedTermProxy)
           @document.class.terminology.retrieve_node(*(term.proxy_pointer.dup << name)) 
        else
          term.retrieve_term(name)
        end
      end

      def [](n)
        ptr = to_pointer
        last = ptr.pop
        OM::XML::DynamicNode.new(n, @document, nil, self)
      end

      def val 
        query = xpath
        trim_text = !query.index("text()").nil?
        @document.find_by_xpath(query).collect {|node| (trim_text ? node.text.strip : node.text) }
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
        #key can either be a pointer or an index
        if (key.kind_of? Fixnum)
          parent.parent.nil? ?  [{parent.key => key}] : parent.parent.to_pointer << {parent.key => key}
        else ### A pointer
          parent.nil? ? [key] : parent.to_pointer << key
        end
      end 

      def xpath
        if parent.nil?
          @document.class.terminology.xpath_with_indexes(*to_pointer)
        else
          chain = retrieve_addressed_node( )
          '//' + chain.map { |n| n.xpath}.join('/')
        end
        
      end


      class AddressedNode
        attr_accessor :xpath, :key, :pointer
        def initialize (pointer, xpath, key)
          self.xpath = xpath
          self.key = key
          self.pointer = pointer
        end
      end
     
      ##
      # This is very similar to Terminology#retrieve_term, however it expands proxy paths out into their cannonical paths
      def retrieve_addressed_node()
         chain = []
            
         if parent
           chain += parent.retrieve_addressed_node()
         end
         if (term.nil?)
           ### This is an index
           node = chain.pop
           node.xpath = OM::XML::TermXpathGenerator.add_node_index_predicate(node.xpath, key)
           chain << node
         elsif (term.kind_of? NamedTermProxy)
            proxy = term.proxy_pointer.dup
            first = proxy.shift
            p = @document.class.terminology.retrieve_node(*first)
            chain << AddressedNode.new(p, p.xpath_relative, self)
            while !proxy.empty?
              first = proxy.shift
              p = p.retrieve_term(first)
              chain << AddressedNode.new(p, p.xpath_relative, self)
            end
         else 
           chain << AddressedNode.new(key, term.xpath_relative, self)
         end
         chain
      end


    end
  end
end
