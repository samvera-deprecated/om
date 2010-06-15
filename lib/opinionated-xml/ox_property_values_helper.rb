require "open-uri"
require "logger"

class OX::ParentNodeNotFoundError < RuntimeError; end
module OX::PropertyValuesHelper
  
  def property_values(lookup_args)
    result = []
    lookup(lookup_args).each {|node| result << node.text }
    return result
  end
  
  def property_values_append(opts={})
    parent_select = opts[:parent_select] 
    child_index = opts[:child_index]
    template = opts[:template]
    new_values = opts[:values]
    
    # If template is a string, use it as the template, otherwise use it as arguments to builder_template
    unless template.instance_of?(String)
      template_args = Array(template)
      if template_args.last.kind_of?(Hash)
        template_opts = template_args.delete_at(template_args.length - 1)
      else
        template_opts = {}
      end
      template = self.class.builder_template( template_args, template_opts )
    end
    
    new_values = Array(new_values)
    # template = self.class.builder_template(property_ref) 
    
    parent_select = Array(parent_select)
    parent_nodeset = lookup(parent_select[0], parent_select[1])
    
    if child_index.kind_of?(Integer)
      parent_node = parent_nodeset[child_index]
    elsif child_index.kind_of?(Symbol) && parent_nodeset.respond_to?(child_index) 
      parent_node = parent_nodeset.send(child_index)
    end
    
    if parent_node.nil?
      raise OX::ParentNodeNotFoundError, "Failed to find a parent node to insert values into based on :parent_select #{parent_select.inspect} with :child_index #{child_index.inspect}"
    end
    
    builder = Nokogiri::XML::Builder.with(parent_node) do |xml|
      new_values.each do |builder_new_value|
        builder_arg = eval('"'+ template + '"') # this inserts builder_new_value into the builder template
        eval(builder_arg)
      end
    end
        
    # Nokogiri::XML::Node.new(builder.to_xml, foo)
    
    return parent_node
    
  end
  
  def property_value_set(property_ref, query_opts, node_index, new_value)
  end
  
end