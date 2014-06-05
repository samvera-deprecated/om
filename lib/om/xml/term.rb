require 'om/xml/term_builder'

# Special options:
# type, index_as, attributes,
# is_root_term, required
#
module OM
  class XML::Term

    include TreeNode
    include XML::TermBuilder

    attr_accessor :name, :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :type, :variant_of, :path, :default_content_path, :is_root_term
    attr_accessor :children, :internal_xml, :terminology

    # Any XML attributes that qualify the Term.
    #
    # @example Declare a Term that has a given attribute (ie. //title[@xml:lang='eng'])
    #   t.english_title(:path=>"title", :attributes=>{"xml:lang"=>"eng"}
    # @example Use nil to point to nodes that do not have a given attribute (ie. //title[not(@xml:lang)])
    #   t.title_without_lang_attribute(:path=>"title", :attributes=>{"xml:lang"=>nil})
    attr_accessor :attributes

    # Namespace Prefix (xmlns) for the Term.
    #
    # By default, OM assumes that all terms in a Terminology have the namespace set in the root of the document.  If you want to set a different namespace for a Term, pass :namespace_prefix into its initializer (or call .namespace_prefix= on its builder)
    # If a node has _no_ namespace, you must explicitly set namespace_prefix to nil.  Currently you have to do this on _each_ term, you can't set namespace_prefix to nil for an entire Terminology.
    #
    # @example
    #   # For xml like this
    #   <foo xmlns="http://foo.com/schemas/fooschema" xmlns:bar="http://bar.com/schemas/barschema">
    #     <address>1400 Pennsylvania Avenue</address>
    #     <bar:latitude>56</bar:latitude>
    #   </foo>
    #
    #   # The Terminology would look like this
    #   OM::XML::Terminology::Builder.new do |t|
    #     t.root(:name=>:foo, :path=>"foo", :xmlns=>"http://foo.com/schemas/fooschema", "xmlns:bar"=>"http://bar.com/schemas/barschema")
    #     t.address
    #     t.latitude(:namespace_prefix=>"bar")
    #   end
    #
    attr_accessor :namespace_prefix


    # h2. Namespaces
    # By default, OM assumes you have no namespace defined unless it is explicitly defined at the root of your document.
    #
    # @param [Symbol] name the name to refer to this term by
    # @param [Hash] opts
    # @option opts [Array]  :index_as a list of indexing hints provided to to_solr
    # @option opts [String] :path partial xpath that points to the node.
    # @option opts [Hash]   :attributes xml attributes to match in the selector
    # @option opts [String] :namespace_prefix xml namespace for this node. If not provided, the default namespace set in the terminology will be used. 
    # @option opts [Symbol] :type one of :string, :date, :time :integer. Defaults to :string
    def initialize(name, opts={}, terminology=nil)
      opts = {:ancestors=>[], :children=>{}}.merge(opts)
      [:children, :ancestors,:path, :index_as, :required, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
        instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )
      end

      self.type = opts[:type] || :string

      unless terminology.nil?
        if opts[:namespace_prefix].nil?
          unless terminology.namespaces["xmlns"].nil?
            @namespace_prefix = "oxns"
          end
        end
      end
      @name = name
      if @path.nil? || @path.empty?
        @path = name.to_s
      end
    end


    def sanitize_new_values(new_values)
        # Sanitize new_values to always be a hash with indexes
        case new_values
        when Hash
          sanitize_new_values(new_values.values)
        when Array
          new_values.map {|v| serialize(v)}
        else
          [serialize(new_values)]
        end
    end

    # @param val [String,Date,Integer]
    def serialize (val)
      return if val.nil?
      case type
      when :date, :integer
        val.to_s
      when :time
        begin
          time = val.to_time
        rescue ArgumentError
          # In Rails 3, an invalid time raises ArgumentError, in Rails 4 it just returns nil
          raise TypeMismatch, "Can't convert `#{val}` to time"
        end
        raise TypeMismatch, "Can't convert `#{val}` to time" if time.nil?
        time.utc.iso8601
      when :boolean
        val.to_s
      else
        val
      end
    end

    # @param [String] val the value (from xml) to deserialize into the correct object type.
    # @return [String,Date,Integer]
    def deserialize(val)
      case type
      when :date
        #TODO use present?
        val.map { |v| !v.empty? ? Date.parse(v) : nil}
      when :time
        #TODO use present?
        val.map { |v| !v.empty? ? DateTime.parse(v) : nil}
      when :integer
        #TODO use blank?
        val.map { |v| v.empty? ? nil : v.to_i}
      when :boolean
        val.map { |v| v == 'true' }
      else 
        val
      end
    end

    def self.from_node(mapper_xml)
      name = mapper_xml.attribute("name").text.to_sym
      attributes = {}
      mapper_xml.xpath("./attribute").each do |a|
        attributes[a.attribute("name").text.to_sym] = a.attribute("value").text
      end
      new_mapper = self.new(name, :attributes=>attributes)
      [:index_as, :required, :type, :variant_of, :path, :default_content_path, :namespace_prefix].each do |accessor_name|
        attribute =  mapper_xml.attribute(accessor_name.to_s)
        unless attribute.nil?
          new_mapper.instance_variable_set("@#{accessor_name}", attribute.text )
        end
      end
      new_mapper.internal_xml = mapper_xml

      mapper_xml.xpath("./mapper").each do |child_node|
        child = self.from_node(child_node)
        new_mapper.add_child(child)
      end

      return new_mapper
    end

    ##
    # Always co-erce :index_as attributes into an Array
    def index_as
      Array(@index_as)
    end

    # crawl down into mapper's children hash to find the desired mapper
    # ie. @test_mapper.retrieve_mapper(:conference, :role, :text)
    def retrieve_term(*pointers)
      children_hash = self.children
      pointers.each do |p|
        if children_hash.has_key?(p)
          target = children_hash[p]
          if pointers.index(p) == pointers.length-1
            return target
          else
            children_hash = target.children
          end
        else
          return nil
        end
      end
      return target
    end

    def is_root_term?
      @is_root_term == true
    end

    def xpath_absolute
      @xpath
    end

    # +term_pointers+ reference to the property you want to generate a builder template for
    # @param [Hash] extra_opts
    # @option extra_opts [Hash] :attributes
    def xml_builder_template(extra_opts = {})
      extra_attributes = extra_opts.fetch(:attributes, {})

      node_options = []
      node_child_template = ""
      if !self.default_content_path.nil?
        node_child_options = ["\':::builder_new_value:::\'"]
        node_child_template = " { xml.#{self.default_content_path}( #{OM::XML.delimited_list(node_child_options)} ) }"
      else
        node_options = ["\':::builder_new_value:::\'"]
      end
      if !self.attributes.nil?
        self.attributes.merge(extra_attributes).each_pair do |k,v|
          node_options << "\'#{k}\'=>\'#{v}\'" unless v == :none
        end
      end

      builder_ref = if self.path.include?(":")
        "xml['#{self.path[0..path.index(":")-1]}']"
      elsif !self.namespace_prefix.nil? and self.namespace_prefix != 'oxns'
        "xml['#{self.namespace_prefix}']"
      else
        "xml"
      end

      attribute = OM::XML.delimited_list(node_options)

      builder_method = if self.path.include?(":")
        "#{self.path[path.index(":")+1..-1]}( #{attribute} )"
      elsif self.path.include?(".")
        "send(:\\\"#{self.path}\\\",  #{attribute} )"
      elsif self.path.kind_of?(Hash) && self.path[:attribute]
        "@#{self.path[:attribute]}( #{OM::XML.delimited_list(node_options)} )"
      elsif Nokogiri::XML::Builder.method_defined? self.path.to_sym
        "#{self.path}_( #{OM::XML.delimited_list(node_options)} )"
      else
        "#{self.path}( #{OM::XML.delimited_list(node_options)} )"
      end
      template = "#{builder_ref}.#{builder_method}#{node_child_template}"
      return template.gsub( /:::(.*?):::/ ) { '#{'+$1+'}' }
    end

    # Generates absolute, relative, and constrained xpaths for the term, setting xpath, xpath_relative, and xpath_constrained accordingly.
    # Also triggers update_xpath_values! on all child nodes, as their absolute paths rely on those of their parent nodes.
    def generate_xpath_queries!
      self.xpath = OM::XML::TermXpathGenerator.generate_absolute_xpath(self)
      self.xpath_constrained = OM::XML::TermXpathGenerator.generate_constrained_xpath(self)
      self.xpath_relative = OM::XML::TermXpathGenerator.generate_relative_xpath(self)
      self.children.each_value {|child| child.generate_xpath_queries! }
      return self
    end

    # Return an XML representation of the Term
    # @param [Hash] options the term will be added to it. If :children=>false, skips rendering child Terms
    # @param [Nokogiri::XML::Document] document (optional) document to insert the term xml into
    # @return [Nokogiri::XML::Document]
    # @example If :children=>false, skips rendering child Terms
    #   term.to_xml(:children=>false)
    # @example You can provide your own Nokogiri document to insert the xml into
    #   doc = Nokogiri::XML::Document.new
    #   term.to_xml({}, document=doc)
    def to_xml(options={}, document=Nokogiri::XML::Document.new)
      builder = Nokogiri::XML::Builder.with(document) do |xml|
        xml.term(:name=>name) {
          if is_root_term?
            xml.is_root_term("true")
          end
          xml.path path
          xml.namespace_prefix namespace_prefix
          unless attributes.nil? || attributes.empty?
            xml.attributes {
              attributes.each_pair do |attribute_name, attribute_value|
                xml.send("#{attribute_name}_".to_sym, attribute_value)
              end
            }
          end
          xml.index_as {
            unless index_as.nil?
              index_as.each  { |index_type| xml.index_type }
            end
          }
          xml.required required
          xml.data_type type
          unless variant_of.nil?
            xml.variant_of variant_of
          end
          unless default_content_path.nil?
            xml.default_content_path default_content_path
          end
          xml.xpath {
            xml.relative xpath_relative
            xml.absolute xpath
            xml.constrained xpath_constrained
          }
          if options.fetch(:children, true)
            xml.children
          end
        }
      end
      doc = builder.doc
      if options.fetch(:children, true)
        children.values.each {|child| child.to_xml(options, doc.xpath("//term[@name=\"#{name}\"]/children").first)}
      end
      return doc
    end

    # private :update_xpath_values
  end
end
