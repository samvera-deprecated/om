module OM
  module XML
    #
    # Provides a natural syntax for using OM Terminologies to access values from xml Documents
    #
    # *Note*: All of these examples assume that @article is an instance of OM::Samples::ModsArticle.  Look at that file to see the Terminology. 
    # 
    # @example Return an array of the value(s) "start page" node(s) from the second issue node within the first journal node
    #   # Using DynamicNode syntax:
    #   @article.journal(0).issue(1).pages.start
    #   # Other ways to perform this query:
    #   @article.find_by_terms({:journal => 0}, {:issue => 1}, :pages, :start)
    #   @article.ng_xml.xpath("//oxns:relatedItem[@type=\"host\"]/oxns:part[2]/extent[@unit="pages"]", {"oxns"=>"http://www.loc.gov/mods/v3"})
    #
    # @example Return an NodeSet of the _first titles_ of all journal nodes
    #   # Using DynamicNode syntax:
    #   @article.journal.title(1)
    #   # Other ways to perform this query:
    #   @article.find_by_terms(:journal, {:title => 1})
    #   @article.ng_xml.xpath("//oxns:relatedItem[@type=\"host\"]/oxns:titleInfo/oxns:title[1]", {"oxns"=>"http://www.loc.gov/mods/v3"})
    #
    # @example Find all of the titles from all journals & return the first title Node from that NodeSet
    #   # Using DynamicNode syntax:
    #   @article.journal.title[1]
    #   # Other ways to perform this query:
    #   @article.find_by_terms(:journal, :title)[1]
    #   @article.ng_xml.xpath("//oxns:relatedItem[@type=\"host\"]/oxns:titleInfo/oxns:title", {"oxns"=>"http://www.loc.gov/mods/v3"})[1]
    #
    class DynamicNode
      instance_methods.each { |m| undef_method m unless m.to_s =~ /^(?:nil\?|send|object_id|to_a)$|^__|^respond_to|proxy_/ }

      attr_accessor :key, :index, :parent, :addressed_node, :term
      def initialize(key, index, document, term, parent=nil)  ##TODO a real term object in here would make it easier to lookup
        self.key = key
        self.index = index
        @document = document
        self.term = term
        self.parent = parent
      end

      def method_missing (name, *args, &block)
        if /=$/.match(name.to_s)
          new_update_node(name, args)
        elsif args.length > 1
          new_update_node_with_index(name, args)
        else
          child = term_child_by_name(term.nil? ? parent.term : term, name)
          if child
            OM::XML::DynamicNode.new(name, args.first, @document, child, self)
          else 
            val.send(name, *args, &block)
          end
        end
      end

      def respond_to?(method)
        super || val.respond_to?(method)
      end

      def new_update_node(name, args)
        modified_name = name.to_s.chop.to_sym
        child = term.retrieve_term(modified_name)
        node = OM::XML::DynamicNode.new(modified_name, nil, @document, child, self)
        node.val=args
      end

      def new_update_node_with_index(name, args)
        index = args.shift
        child = term.retrieve_term(name)
        node = OM::XML::DynamicNode.new(name, index, @document, child, self)
        node.val=args
      end

      def val=(args)
        @document.ng_xml_will_change!
        new_values = term.sanitize_new_values(args.first)
        existing_nodes = @document.find_by_xpath(xpath)
        if existing_nodes.length > new_values.length
          starting_index = new_values.length + 1
          starting_index.upto(existing_nodes.size).each do |index|
            @document.term_value_delete select: xpath, child_index: index
          end
        end
        new_values.each_with_index do |z, y|
## If we pass something that already has an index on it, we should be able to add it.
          if existing_nodes[y.to_i].nil?
            parent_pointer = if parent
              parent.to_pointer
            elsif term.is_a? NamedTermProxy
              term.proxy_pointer[0..-2]
            end
            @document.term_values_append(:parent_select=> parent_pointer,:parent_index=>0,:template=>to_pointer,:values=>z)
          else
            @document.term_value_update(xpath, y.to_i, z)
          end
        end
      end


      def term_child_by_name(term, name)
        if (term.kind_of? NamedTermProxy)
           @document.class.terminology.retrieve_node(*(term.proxy_pointer.dup << name)) 
        else
          term.retrieve_term(name)
        end
      end

      # This resolves the target of this dynamic node into a reified Array
      # @return [Array]
      def val 
        query = xpath
        trim_text = !query.index("text()").nil?
        val = @document.find_by_xpath(query).collect {|node| (trim_text ? node.text.strip : node.text) }
        term.deserialize(val)
      end

      def nodeset
        query = xpath
        trim_text = !query.index("text()").nil?
        return @document.find_by_xpath(query)
      end

      def delete
        nodeset.delete
      end
      
      def inspect
        val.inspect
      end

      def ==(other)
        other == val
      end

      def !=(other)
        val != other
      end

      def eql?(other)
        self == other
      end

      def to_pointer
        if self.index
          parent.nil? ?  [{key => index}] : parent.to_pointer << {key => index}
        else ### A pointer
          parent.nil? ? [key] : parent.to_pointer << key
        end
      end 

      def xpath
        if parent.nil?
          @document.class.terminology.xpath_with_indexes(*(to_pointer << {})) ### last element is always filters
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
         if (self.index)
           ### This is an index
           node = AddressedNode.new(key, term.xpath_relative, self)
           node.xpath = OM::XML::TermXpathGenerator.add_node_index_predicate(node.xpath, index)
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
