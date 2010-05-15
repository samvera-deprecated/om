require "open-uri"
require "logger"

module OX::PropertyValuesHelper
  
  def property_values_for(lookup_args)
    result = []
    lookup(lookup_args).each {|node| result << node.text }
    return result
  end
  
  def property_values_append_for(lookup_args)
  end
  
  def property_values_set_for(lookup_args)
  end
  
end