module OM::XML::NodeGenerator
    
  # Module Methods -- These methods can be called directly on the Module itself
  def self.generate(term, builder_new_value, opts={})
    template = term.xml_builder_template(opts)
    builder_call_body = eval('"' + template + '"')
    builder = Nokogiri::XML::Builder.new do |xml|
      eval( builder_call_body )
    end
    
    return builder.doc
  end

end