module OM
  module XML
    class DynamicNode
      def initialize(term, document, parent=nil)
        @term = term
        @document = document
        @parent = parent
      end


      def method_missing (name, *args)
        begin
          term = @document.class.terminology.retrieve_term( *(to_pointer << name) )
          OM::XML::DynamicNode.new(name, @document, self)
        rescue OM::XML::Terminology::BadPointerError
          val.send(name, *args)
        end
      end

      def val 
        @document.term_values( *to_pointer )
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
