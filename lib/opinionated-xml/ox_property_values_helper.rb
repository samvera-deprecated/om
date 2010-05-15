require "open-uri"
require "logger"

module OX::PropertyValuesHelper
  
  def property_values(lookup_args)
    result = []
    lookup(lookup_args).each {|node| result << node.text }
    return result
  end
  
  def property_value_append(property_ref, query_opts={}, new_values=[])
    new_values = Array(new_values)
    parent_node = lookup(property_ref, query_opts).first.parent
    template = builder_template(property_ref) 
    
    Nokogiri::XML::Builder.with(parent_node) do |xml|
      new_values.each do |builder_new_value|
        builder_arg = eval('"'+ template + '"') # this inserts builder_new_value into the builder template
        eval(builder_arg)
      end
    end
    
  end
  
  def property_value_set(property_ref, query_opts, node_index, new_value)
  end
  
end