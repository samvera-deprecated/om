module OM::XML::Container
  extend ActiveSupport::Concern
  
  attr_accessor :ng_xml
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    
    # @param [String,File,Nokogiri::XML::Node] xml
    # @param [ActiveFedora::Datastream] tmpl 
    # Careful! If you call this from a constructor, be sure to provide something 'ie. self' as the @tmpl. Otherwise, you will get an infinite loop!
    def from_xml(xml=nil, tmpl=self.new) # :nodoc:
      if xml.nil?
        # noop: handled in #ng_xml accessor..  tmpl.ng_xml = self.xml_template
      elsif xml.kind_of? Nokogiri::XML::Node
        tmpl.ng_xml = xml
      else
        tmpl.ng_xml = Nokogiri::XML::Document.parse(xml)
      end
      return tmpl
    end
    
    # By default, new OM Document instances will create an empty xml document, but if you override self.xml_template to return a different object (e.g. Nokogiri::XML::Document), that will be created instead.
    # You can make this method create the documents however you want as long as it returns a Nokogiri::XML::Document.
    # In the tutorials, we use Nokogiri::XML::Builder in this mehtod and call its .doc method at the end of xml_template in order to return the Nokogiri::XML::Document object. Instead of using Nokogiri::XML::Builder, you could put your template into an actual xml file and have xml_template use Nokogiri::XML::Document.parse to load it. That’s up to you. 
    # @return [Nokogiri::XML::Document]
    def xml_template
      Nokogiri::XML::Document.parse("")
    end
    
  end
  
  def ng_xml
    @ng_xml ||= self.class.xml_template
  end

  # Instance Methods -- These methods will be available on instances of classes that include this module
  
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
