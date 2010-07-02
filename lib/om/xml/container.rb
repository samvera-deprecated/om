module OM::XML::Container
  
  attr_accessor :ng_xml
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    # @xml String, File or Nokogiri::XML::Node
    # @tmpl ActiveFedora::MetadataDatastream
    # Careful! If you call this from a constructor, be sure to provide something 'ie. self' as the @tmpl. Otherwise, you will get an infinite loop!
    def from_xml(xml=nil, tmpl=self.new) # :nodoc:
      if xml.nil?
        tmpl.ng_xml = self.xml_template
      elsif xml.kind_of? Nokogiri::XML::Node
        tmpl.ng_xml = xml
      else
        tmpl.ng_xml = Nokogiri::XML::Document.parse(xml)
      end
      return tmpl
    end
    
    def xml_template
      Nokogiri::XML::Document.parse("")
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
    
  def to_xml(xml = ng_xml)
    if xml == ng_xml
      return xml.to_xml
    elsif ng_xml.root.nil?
        return xml.to_xml
    elsif xml.kind_of?(Nokogiri::XML::Document)
        xml.root.add_child(ng_xml.root)
        return xml.to_xml
    elsif xml.kind_of?(Nokogiri::XML::Node)
        xml.add_child(ng_xml.root)
        return xml.to_xml
    else
        raise "You can only pass instances of Nokogiri::XML::Node into this method.  You passed in #{xml}"
    end
  end
  
end