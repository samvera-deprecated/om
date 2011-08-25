require "om/xml/container"
require "om/xml/validation"

require "om/xml/terminology"
require "om/xml/term"
require "om/xml/term_xpath_generator"
require "om/xml/node_generator"
require "om/xml/term_value_operators"
require "om/xml/named_term_proxy"
require "om/xml/document"
require "om/xml/dynamic_node"

require "om/xml/template_registry"

module OM::XML
  
  # Raised when the XML document or XML template can't be found during an operation
  class TemplateMissingException < StandardError; end
  
  attr_accessor :ng_xml
  
  # Module Methods -- These methods can be called directly on the Module itself
  
  # Transforms an array of values into a string delimited by +delimiter+
  def self.delimited_list( values_array, delimiter=", ")
    result = values_array.collect{|a| a + delimiter}.to_s.chomp(delimiter)
  end
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    # @pointer accessor or property info pointer
    # 
    # ex. [[:person,1],:role] will be converted to [{:person=>1},:role]
    def sanitize_pointer(pointer) 
      if pointer.kind_of?(Array)        
        pointer.each do |x|
          if x.kind_of?(Array)
            pointer[pointer.index(x)] = Hash[x[0],x[1]] 
          end
        end
      end
      return pointer
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:include, OM::XML::Container)
    klass.send(:include, OM::XML::Validation)
  end
  
  
end
