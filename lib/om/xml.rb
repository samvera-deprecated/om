require "om/xml/container"
require "om/xml/accessors"
require "om/xml/validation"
require "om/xml/properties"

module OM::XML
  
  attr_accessor :ng_xml
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.send(:include, OM::XML::Container)
    klass.send(:include, OM::XML::Accessors)
    klass.send(:include, OM::XML::Validation)
    klass.send(:include, OM::XML::Properties)

    # klass.send(:include, OM::XML::Schema)
  end
  
end
