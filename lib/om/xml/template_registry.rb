class OM::XML::TemplateRegistry

  def initialize
    @templates = {}
  end

  # Define an XML template
  # @param [Symbol] a node_type key to associate with this template
  # @param [Block] a block that will receive a [Nokogiri::XML::Builder] object and any arbitrary parameters passed to +instantiate+
  # @return the +node_type+ Symbol
  def define(node_type, &block)
    unless node_type.is_a?(Symbol)
      raise TypeError, "Registered node type must be a Symbol (e.g., :person)"
    end
  
    @templates[node_type] = block
    node_type
  end

  # Undefine an XML template
  # @param [Symbol] the node_type key of the template to undefine
  # @return the +node_type+ Symbol
  def undefine(node_type)
    @templates.delete(node_type)
    node_type
  end

  # Check whether a particular node_type is defined
  # @param [Symbol] the node_type key to check
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
  # @param [Symbol] the node_type to instantiate
  # @param additional arguments to pass to the template
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
  def add_child(target_node, node_type, *args)
    attach_node(:add_child, target_node, :self, node_type, *args)
  end

  # +instantiate+ a node and add it as a following sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return the new [Nokogiri::XML::Node]
  def add_next_sibling(target_node, node_type, *args)
    attach_node(:add_next_sibling, target_node, :parent, node_type, *args)
  end

  # +instantiate+ a node and add it as a preceding sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return the new [Nokogiri::XML::Node]
  def add_previous_sibling(target_node, node_type, *args)
    attach_node(:add_previous_sibling, target_node, :parent, node_type, *args)
  end

  # +instantiate+ a node and add it as a following sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return +target_node+
  def after(target_node, node_type, *args)
    attach_node(:after, target_node, :parent, node_type, *args)
  end

  # +instantiate+ a node and add it as a preceding sibling of the [Nokogiri::XML::Node] specified by +target_node+
  # @return +target_node+
  def before(target_node, node_type, *args)
    attach_node(:before, target_node, :parent, node_type, *args)
  end

  # +instantiate+ a node replace the [Nokogiri::XML::Node] specified by +target_node+ with it
  # @return the new [Nokogiri::XML::Node]
  def replace(target_node, node_type, *args)
    attach_node(:replace, target_node, :parent, node_type, *args)
  end

  # +instantiate+ a node replace the [Nokogiri::XML::Node] specified by +target_node+ with it
  # @return +target_node+
  def swap(target_node, node_type, *args)
    attach_node(:swap, target_node, :parent, node_type, *args)
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

  def attach_node(method, target_node, builder_node_offset, node_type, *args)
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
    return result
  end
  
  def empty_root_node
    Nokogiri::XML('<root/>').root
  end
  
end
