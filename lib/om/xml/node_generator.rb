module OM::XML::NodeGenerator
    
  # Module Methods -- These methods can be called directly on the Module itself
  # @param [OM::XML::Term] term The term to generate a node based on
  # @param [String] builder_new_value The new value to insert into the generated node
  # @return [Nokogiri::XML::Document]
  #
  # Ex.
  # term = t.retrieve_term(:person, :first_name)
  # OM::XML::NodeGenerator.generate(term, "John")
  def self.generate(term, builder_new_value, opts={})
    template = term.xml_builder_template(opts)
    builder_call_body = eval('"' + template + '"')
    builder = Nokogiri::XML::Builder.new do |xml|
      eval( builder_call_body )
    end
    
    return builder.doc
  end

end
