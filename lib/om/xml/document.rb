module OM::XML::Document


  # Class Methods -- These methods will be available on classes that include this Module

  module ClassMethods

    attr_accessor :terminology, :template_registry

    # Sets the OM::XML::Terminology for the Document
    # Expects +&block+ that will be passed into OM::XML::Terminology::Builder.new
    def set_terminology &block
      @terminology = OM::XML::Terminology::Builder.new( &block ).build
    end

    # Define a new node template with the OM::XML::TemplateRegistry.
    # * +name+ is a Symbol indicating the name of the new template.
    # * The +block+ does the work of creating the new node, and will receive
    #   a Nokogiri::XML::Builder and any other args passed to one of the node instantiation methods.
    def define_template name, &block
      @template_registry ||= OM::XML::TemplateRegistry.new
      @template_registry.define name, &block
    end

    # Returns any namespaces defined by the Class' Terminology
    def ox_namespaces
      if @terminology.nil?
        return {}
      else
        return @terminology.namespaces
      end
    end

  end

  # Instance Methods -- These methods will be available on instances of classes that include this module

  attr_accessor :ox_namespaces

  def self.included(klass)
    klass.extend(ClassMethods)

    klass.send(:include, OM::XML::Container)
    klass.send(:include, OM::XML::TermValueOperators)
    klass.send(:include, OM::XML::Validation)
  end

  def method_missing(name, *args)
    if matches = /([^=]*)=$/.match(name.to_s)
      modified_name = matches[1].to_sym
      term = self.class.terminology.retrieve_term(modified_name)
      if (term)
        node = OM::XML::DynamicNode.new(modified_name, nil, self, term)
        node.val=args
      else
        super
      end
    else
      term = self.class.terminology.retrieve_term(name)
      if (term)
        OM::XML::DynamicNode.new(name, args.first, self, term)
      else
        super
      end
    end


  end


  def find_by_xpath(xpath)
    if ox_namespaces.values.compact.empty?
      ng_xml.xpath(xpath)
    else
      ng_xml.xpath(xpath, ox_namespaces)
    end
  end


  # Applies the property's corresponding xpath query, returning the result Nokogiri::XML::NodeSet
  def find_by_terms_and_value(*term_pointer)
    xpath = self.class.terminology.xpath_for(*term_pointer)
    find_by_xpath(xpath) unless xpath.nil?
  end


  # +term_pointer+ Variable length array of values in format [:accessor_name, :accessor_name ...] or [{:accessor_name=>index}, :accessor_name ...]
  # @example:
  #   find_by_terms( {:person => 1}, :first_name )
  # @example
  #   find_by_terms( [:person, 1, :first_name] )
  # Currently, indexes must be integers.
  # @example Pass in your own xpath query if you don't want to bother with Term pointers but do want OM to handle namespaces for you.
  #   find_by_terms('//oxns:name[@type="personal"][contains(oxns:role, "donor")]')
  def find_by_terms(*term_pointer)
    xpath = self.class.terminology.xpath_with_indexes(*term_pointer)
    find_by_xpath(xpath) unless xpath.nil?
  end

  # Test whether the document has a node corresponding to the given term_pointer
  # @param [Array] term_pointer to test
  def node_exists?(*term_pointer)
    !find_by_terms(*term_pointer).empty?
  end

  # Access the class's template registry
  def template_registry
    self.class.template_registry
  end

  def template(node_type, *args)
    template_registry.instantiate(node_type, *args)
  end

  # Instantiate a +node_type+ template and add it as a child of +target_node+, where +target_node+ is one of:
  # * a Nokogiri::XML::Node
  # * a single-element Nokogiri::XML::NodeSet
  # * a +term_pointer+ array resolving to a single-element Nokogiri::XML::NodeSet
  # Additional arguments will be passed to the template unaltered.
  #
  # Returns the new Nokogiri::XML::Node.
  def add_child_node(target_node, node_type, *args, &block)
    manipulate_node(:add_child, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and insert it as the following sibling of +target_node+.
  # Returns the new Nokogiri::XML::Node.
  def add_next_sibling_node(target_node, node_type, *args, &block)
    manipulate_node(:add_next_sibling, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and insert it as the preceding sibling of +target_node+.
  # Returns the new Nokogiri::XML::Node.
  def add_previous_sibling_node(target_node, node_type, *args, &block)
    manipulate_node(:add_previous_sibling, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and insert it as the following sibling of +target_node+.
  # Returns +target_node+.
  def after_node(target_node, node_type, *args, &block)
    manipulate_node(:after, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and insert it as the preceding sibling of +target_node+.
  # Returns +target_node+.
  def before_node(target_node, node_type, *args, &block)
    manipulate_node(:before, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and replace +target_node+ with it.
  # Returns the new Nokogiri::XML::Node.
  def replace_node(target_node, node_type, *args, &block)
    manipulate_node(:replace, target_node, node_type, *args, &block)
  end

  # Instantiate a +node_type+ template and replace +target_node+ with it.
  # Returns +target_node+.
  def swap_node(target_node, node_type, *args, &block)
    manipulate_node(:swap, target_node, node_type, *args, &block)
  end

  # Returns a hash combining the current documents namespaces (provided by nokogiri) and any namespaces that have been set up by your Terminology.
  # Most importantly, this matches the 'oxns' namespace to the namespace you provided in your Terminology's root term config
  def ox_namespaces
    @ox_namespaces ||= ng_xml.namespaces.merge(self.class.ox_namespaces)
  end

  private
  def manipulate_node(method, target, *args, &block)
    if target.is_a?(Array)
      target = self.find_by_terms(*target)
    end
    template_registry.send(method, target, *args, &block)
  end
end
