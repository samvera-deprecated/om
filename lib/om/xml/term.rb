# Special options:
# data_type, index_as, attributes,
# is_root_term, required
#
class OM::XML::Term

  # Term::Builder Class Definition
  #
  # @example
  #   tb2 = OM::XML::Term::Builder.new("my_term_name").path("fooPath").attributes({:lang=>"foo"}).index_as([:searchable, :facetable]).required(true).data_type(:text)
  #
  #
  #
  # When coding against Builders, remember that they rely on MethodMissing,
  # so any time you call a method on the Builder that it doesn't explicitly recognize,
  # the Builder will add your method & arguments to the it's settings and return itself.
  class Builder
    attr_accessor :name, :settings, :children, :terminology_builder

    def initialize(name, terminology_builder=nil)
      @name = name.to_sym
      @terminology_builder = terminology_builder
      @settings = {:required=>false, :data_type=>:string}
      @children = {}
    end

    def add_child(child)
      @children[child.name] = child
    end

    def retrieve_child(child_name)
      child = @children.fetch(child_name, nil)
    end

    def lookup_refs(nodes_visited=[])
      result = []
      if @settings[:ref]
        # Fail if we do not have terminology builder
        if self.terminology_builder.nil?
          raise "Cannot perform lookup_ref for the #{self.name} builder.  It doesn't have a reference to any terminology builder"
        end
        target = self.terminology_builder.retrieve_term_builder(*@settings[:ref])

        # Fail on circular references and return an intelligible error message
        if nodes_visited.include?(target)
          nodes_visited << self
          nodes_visited << target
          trail = ""
          nodes_visited.each_with_index do |node, z|
            trail << node.name.inspect
            unless z == nodes_visited.length-1
              trail << " => "
            end
          end
          raise OM::XML::Terminology::CircularReferenceError, "Circular reference in Terminology: #{trail}"
        end
        result << target
        result.concat( target.lookup_refs(nodes_visited << self) )
      end
      return result
    end

    # If a :ref value has been set, looks up the target of that ref and merges the target's settings & children with the current builder's settings & children
    # operates recursively, so it is possible to apply refs that in turn refer to other nodes.
    def resolve_refs!
      name_of_last_ref = nil
      lookup_refs.each_with_index do |ref,z|
        @settings = two_layer_merge(@settings, ref.settings)
        @children.merge!(ref.children)
        name_of_last_ref = ref.name
      end
      if @settings[:path].nil? && !name_of_last_ref.nil?
        @settings[:path] = name_of_last_ref.to_s
      end
      @settings.delete :ref
      return self
    end

    # Returns a new Hash that merges +downstream_hash+ with +upstream_hash+
    # similar to calling +upstream_hash+.merge(+downstream_hash+) only it also merges
    # any internal values that are themselves Hashes.
    def two_layer_merge(downstream_hash, upstream_hash)
      up = upstream_hash.dup
      dn = downstream_hash.dup
      up.each_pair do |setting_name, value|
        if value.kind_of?(Hash) && downstream_hash.has_key?(setting_name)
          dn[setting_name] = value.merge(downstream_hash[setting_name])
          up.delete(setting_name)
        end
      end
      return up.merge(dn)
    end

    # Builds a new OM::XML::Term based on the Builder object's current settings
    # If no path has been provided, uses the Builder object's name as the term's path
    # Recursively builds any children, appending the results as children of the Term that's being built.
    # @param [OM::XML::Terminology] terminology that this Term is being built for
    def build(terminology=nil)
      self.resolve_refs!
      if term.self.settings.has_key?(:proxy)
        term = OM::XML::NamedTermProxy.new(self.name, self.settings[:proxy], terminology, self.settings)
      else
        term = OM::XML::Term.new(self.name, {}, terminology)

        self.settings.each do |name, values|
          if term.respond_to?(name.to_s+"=")
            term.instance_variable_set("@#{name}", values)
          end
        end
        @children.each_value do |child|
          term.add_child child.build(terminology)
        end
        term.generate_xpath_queries!
      end

      return term
    end

    # Any unknown method calls will add an entry to the settings hash and return the current object
    def method_missing method, *args, &block
      if args.length == 1
        args = args.first
      end
      @settings[method] = args
      return self
    end
  end

  #
  # Class Definition for Term
  #

  include OM::TreeNode

  attr_accessor :name, :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :data_type, :variant_of, :path, :default_content_path, :is_root_term
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
  # If you want to specify which namespace a term is using, use:
  #   namspace_prefix => "bar"
  # This value defaults to nil, in which case if a default namespace is set in the termnology, that namespace will be used.
  def initialize(name, opts={}, terminology=nil)
    opts = {:ancestors=>[], :children=>{}}.merge(opts)
    [:children, :ancestors,:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )
    end
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
  # @opts
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
    builder_ref = "xml"
    builder_method = self.path
    if builder_method.include?(":")
      builder_ref = "xml['#{self.path[0..path.index(":")-1]}']"
      builder_method = self.path[path.index(":")+1..-1]
    elsif !self.namespace_prefix.nil? and self.namespace_prefix != 'oxns'
      builder_ref = "xml['#{self.namespace_prefix}']"
    elsif self.path.kind_of?(Hash) && self.path[:attribute]
      builder_method = "@#{self.path[:attribute]}"
    end
    if Nokogiri::XML::Builder.method_defined? builder_method.to_sym
      builder_method += "_"
    end
    template = "#{builder_ref}.#{builder_method}( #{OM::XML.delimited_list(node_options)} )" + node_child_template
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
  # @param [Hash] options, the term will be added to it. If :children=>false, skips rendering child Terms
  # @param [Nokogiri::XML::Document] (optional) document to insert the term xml into
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
        xml.data_type data_type
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
