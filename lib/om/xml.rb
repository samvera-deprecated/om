require 'active_support'
module OM::XML
  extend ActiveSupport::Autoload 
  autoload :Container
  autoload :Validation
  autoload :Terminology
  autoload :Term
  autoload :TerminologyBasedSolrizer
  autoload :TermXpathGenerator
  autoload :NodeGenerator
  autoload :TermValueOperators
  autoload :NamedTermProxy
  autoload :Document
  autoload :DynamicNode
  autoload :TemplateRegistry

  # Raised when the XML document or XML template can't be found during an operation
  class TemplateMissingException < StandardError; end
  
  attr_accessor :ng_xml
  
  # Module Methods -- These methods can be called directly on the Module itself
  
  # Transforms an array of values into a string delimited by +delimiter+
  def self.delimited_list( values_array, delimiter=", ")
    values_array.join(delimiter)
  end
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    # @param pointer accessor or property info pointer
    # @example
    #   [[:person,1],:role] #=> [{:person=>1},:role]
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
