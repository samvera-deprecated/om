module OM::XML::Generator
  
  attr_accessor :ng_xml
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    def generate(property_ref, builder_new_value, opts={})
      template = builder_template(property_ref, opts)
      builder_call_body = eval('"' + template + '"')
      builder = Nokogiri::XML::Builder.new do |xml|
        eval( builder_call_body )
      end
      
      return builder.doc
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
end