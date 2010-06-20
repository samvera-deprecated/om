module OM::XML::Container
  
  attr_accessor :ng_xml
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    # @xml Sting, File or Nokogiri::XML::Node
    # @tmpl ActiveFedora::MetadataDatastream
    def from_xml(xml, tmpl=self.new) # :nodoc:
      if xml.kind_of? Nokogiri::XML::Node
        tmpl.ng_xml = xml
      else
        tmpl.ng_xml = Nokogiri::XML::Document.parse(xml)
      end
      return tmpl
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
    
  def to_xml
    ng_xml.to_xml
  end
  
end