module OM
  module XML
    class DynamicNode
      def initialize(term, document, parent=nil)
        @term = term
        @document = document
        @parent = parent
      end


      def method_missing (name, *args)
        #puts "MethodMissing DN: #{name}"
        term = @document.class.terminology.retrieve_node( *(to_pointer << name) )
        if term.nil?
          val.send(name, *args)
        else 
          OM::XML::DynamicNode.new(name, @document, self)
        end
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
        @parent.nil? ? [@term] : @parent.to_pointer << @term
      end 

    end
  end
end
