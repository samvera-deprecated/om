require "om/xml/container"
require "om/xml/accessors"
require "om/xml/validation"
require "om/xml/properties"
require "om/xml/property_value_operators"
require "om/xml/generator"

require "om/xml/terminology"
require "om/xml/term"
require "om/xml/term_xpath_generator"
require "om/xml/document"


module OM::XML
  
  attr_accessor :ng_xml
  
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
    klass.send(:include, OM::XML::Accessors)
    klass.send(:include, OM::XML::Validation)
    klass.send(:include, OM::XML::Properties)
    klass.send(:include, OM::XML::PropertyValueOperators)
    klass.send(:include, OM::XML::Generator)
  end
  
end
