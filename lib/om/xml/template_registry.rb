# Extend an OM::XML::Document with reusable templates, then use them to add content to 
# instance documents.
#
# Example:
#
#   require 'om/samples/mods_article'
# 
#   class OM::Samples::ModsArticle
#     define_template :personalName do |xml, family, given, address|
#       xml.name(:type => 'personal') do
#         xml.namePart(:type => 'family') { xml.text(family) }
#         xml.namePart(:type => 'given') { xml.text(given) }
#         xml.namePart(:type => 'termsOfAddress') { xml.text(address) }
#       end
#     end
# 
#     define_template :role do |xml, text, attrs|
#       xml.role do
#         attrs = { :type => 'text' }.merge(attrs)
#         xml.roleTerm(attrs) { xml.text(text) }
#       end
#     end
#   end
# 
#   mods = OM::Samples::ModsArticle.from_xml(File.read('./spec/fixtures/CBF_MODS/ARS0025_016.xml'))
# 
#   mods.add_previous_sibling_node([:person => 0], :personalName, 'Shmoe', 'Joseph', 'Dr.') { |person|
#     person.add_child(mods.template(:role, 'author', :authority => 'marcrelator'))
#     person.add_child(mods.template(:role, 'sub', :authority => 'local', :type => 'code'))
#     person
#   }

class OM::XML::TemplateRegistry

  def initialize(templates={})
    @templates = templates.dup
  end

  # Define an XML template
  # @param [Symbol] node_type key to associate with this template
  # @yield [builder] a block that will receive a [Nokogiri::XML::Builder] object and any arbitrary parameters passed to +instantiate+
  # @yieldparam [Nokogiri::XML::Builder]
  # @return the +node_type+ Symbol
  def define(node_type, &block)
    unless node_type.is_a?(Symbol)
      raise TypeError, "Registered node type must be a Symbol (e.g., :person)"
    end
  
    @templates[node_type] = block
    node_type
  end

  # Undefine an XML template
  # @param [Symbol] node_type the node_type key of the template to undefine
  # @return the +node_type+ Symbol
  def undefine(node_type)
    @templates.delete(node_type)
    node_type
  end

  # Check whether a particular node_type is defined
  # @param [Symbol] node_type the node_type key to check
  # @return [True] or [False]
  def has_node_type?(node_type)
    @templates.has_key?(node_type)
  end

  # List defined node_types
  # @return [Array] of node_type symbols.
  def node_types
    @templates.keys
  end

  # Instantiate a detached, standalone node
  # @param [Symbol] node_type the node_type to instantiate
  # @param [Hash] args additional arguments to pass to the template
  def instantiate(node_type, *args)
    result = create_detached_node(nil, node_type, *args)
    # Strip namespaces from text and CDATA nodes. Stupid Nokogiri.
    result.traverse { |node|
      if node.is_a?(Nokogiri::XML::CharacterData)
        node.namespace = nil
      end
    }
    return result
  end

  # +instantiate+ a node and add it as a child of the [Nokogiri::XML::Node] specified by +target_node+
  # @return the new [Nokogiri::XML::Node]
  def add_child(target_node, node_type, *args, &block)
    attach_node(:add_child, target_node, :self, node_type, *args, &block)
  end

  # +instantiate+ a node and add it as a following sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return the new [Nokogiri::XML::Node]
  def add_next_sibling(target_node, node_type, *args, &block)
    attach_node(:add_next_sibling, target_node, :parent, node_type, *args, &block)
  end

  # +instantiate+ a node and add it as a preceding sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return the new [Nokogiri::XML::Node]
  def add_previous_sibling(target_node, node_type, *args, &block)
    attach_node(:add_previous_sibling, target_node, :parent, node_type, *args, &block)
  end

  # +instantiate+ a node and add it as a following sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return +target_node+
  def after(target_node, node_type, *args, &block)
    attach_node(:after, target_node, :parent, node_type, *args, &block)
  end

  # +instantiate+ a node and add it as a preceding sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return +target_node+
  def before(target_node, node_type, *args, &block)
    attach_node(:before, target_node, :parent, node_type, *args, &block)
  end

  # +instantiate+ a node replace the [Nokogiri::XML::Node] specified by +target_node+ with it
  # @return the new [Nokogiri::XML::Node]
  def replace(target_node, node_type, *args, &block)
    attach_node(:replace, target_node, :parent, node_type, *args, &block)
  end

  # +instantiate+ a node replace the [Nokogiri::XML::Node] specified by +target_node+ with it
  # @return +target_node+
  def swap(target_node, node_type, *args, &block)
    attach_node(:swap, target_node, :parent, node_type, *args, &block)
  end
  
  def dup
    result = self.class.new(@templates)
    result
  end

  def methods
    super + @templates.keys.collect { |k| k.to_s }
  end

  def method_missing(sym,*args)
    sym = sym.to_s.sub(/_$/,'').to_sym
    if @templates.has_key?(sym)
      instantiate(sym,*args)
    else
      super(sym,*args)
    end
  end

  private
  
  # Create a new Nokogiri::XML::Node based on the template for +node_type+
  #
  # @param [Nokogiri::XML::Node] builder_node The node to use as starting point for building the node using Nokogiri::XML::Builder.with(builder_node).  This provides namespace info, etc for constructing the new Node object. If nil, defaults to {OM::XML::TemplateRegistry#empty_root_node}.  This is just used to create the new node and will not be included in the response.
  # @param node_type a pointer to the template to use when creating the node
  # @param [Array] args any additional args
  def create_detached_node(builder_node, node_type, *args)
    proc = @templates[node_type]
    if proc.nil?
      raise NameError, "Unknown node type: #{node_type.to_s}"
    end
    if builder_node.nil?
      builder_node = empty_root_node
    end
    
    builder = Nokogiri::XML::Builder.with(builder_node) do |xml|
      proc.call(xml,*args)
    end
    builder_node.elements.last.remove
  end

  # Create a new XML node of type +node_type+ and attach it to +target_node+ using the specified +method+
  #
  # @param [Symbol] method name that should be called on +target_node+, usually a Nokogiri::XML::Node instance method
  # @param [Nokogiri::XML::Node or Nokogiri::XML::NodeSet with only one Node in it] target_node
  # @param [Symbol] builder_node_offset Indicates node to use as the starting point for _constructing_ the new node using {OM::XML::TemplateRegistry#create_detached_node}. If this is set to :parent, target_node.parent will be used.  Otherwise, target_node will be used. 
  # @param node_type
  # @param [Array] args any additional arguments for creating the node
  def attach_node(method, target_node, builder_node_offset, node_type, *args, &block)
    if target_node.is_a?(Nokogiri::XML::NodeSet) and target_node.length == 1
      target_node = target_node.first
    end
    builder_node = builder_node_offset == :parent ? target_node.parent : target_node
    new_node = create_detached_node(builder_node, node_type, *args)
    result = target_node.send(method, new_node)
    # Strip namespaces from text and CDATA nodes. Stupid Nokogiri.
    new_node.traverse { |node|
      if node.is_a?(Nokogiri::XML::CharacterData)
        node.namespace = nil
      end
    }
    if block_given?
      yield result
    else
      return result
    end
  end
  
  def empty_root_node
    Nokogiri::XML('<root/>').root
  end
  
end
