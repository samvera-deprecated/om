module OM::XML::Document
    
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    attr_accessor :terminology, :templates
  
    # Sets the OM::XML::Terminology for the Document
    # Expects +&block+ that will be passed into OM::XML::Terminology::Builder.new
    def set_terminology &block
      @terminology = OM::XML::Terminology::Builder.new( &block ).build
    end
    
    def define_template name, &block
      @templates ||= OM::XML::TemplateRegistry.new
      @templates.define name, &block
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
  end
  
  # Applies the property's corresponding xpath query, returning the result Nokogiri::XML::NodeSet
  def find_by_terms_and_value(*term_pointer)
    xpath = self.class.terminology.xpath_for(*term_pointer)    
    if xpath.nil?
      return nil
    else
      return ng_xml.xpath(xpath, ox_namespaces) 
    end
  end
  

  # +term_pointer+ Variable length array of values in format [:accessor_name, :accessor_name ...] or [{:accessor_name=>index}, :accessor_name ...]
  # example: {:person => 1}, :first_name
  # example: [:person, 1, :first_name]
  # Currently, indexes must be integers.
  def find_by_terms(*term_pointer)
    xpath = self.class.terminology.xpath_with_indexes(*term_pointer)   
    if xpath.nil?
      return nil
    else
      return ng_xml.xpath(xpath, ox_namespaces) 
    end   
  end

  # Access the class's template registry
  def templates
    self.class.templates
  end
  
  # Convenience pass-through methods integrating +find_by_terms+ support directly into templates
  # Methods ending in 
  # example: doc.add_child_node([*term_pointer], :node_type, *args) is the same as doc.templates.add_child(doc.find_by_terms(*term_pointer), :node_type, *args)
  def manipulate_node(method, target, *args)
    if target.is_a?(Array)
      target = self.find_by_terms(*target)
    end
    templates.send(method, target, *args)
  end
  def add_child_node(*args);            manipulate_node(:add_child, *args);            end
  def add_next_sibling_node(*args);     manipulate_node(:add_next_sibling, *args);     end
  def add_previous_sibling_node(*args); manipulate_node(:add_previous_sibling, *args); end
  def after_node(*args);                manipulate_node(:after, *args);                end
  def before_node(*args);               manipulate_node(:before, *args);               end
  def replace_node(*args);              manipulate_node(:replace, *args);              end
  def swap_node(*args);                 manipulate_node(:swap, *args);                 end
  
  # Returns a hash combining the current documents namespaces (provided by nokogiri) and any namespaces that have been set up by your Terminology.
  # Most importantly, this matches the 'oxns' namespace to the namespace you provided in your Terminology's root term config
  def ox_namespaces
    @ox_namespaces ||= ng_xml.namespaces.merge(self.class.ox_namespaces)
  end
  
end