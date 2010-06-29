require "open-uri"
require "logger"

class OM::XML::ParentNodeNotFoundError < RuntimeError; end
module OM::XML::PropertyValueOperators
  
  def property_values(lookup_args)
    result = []
    lookup(lookup_args).each {|node| result << node.text }
    return result
  end
  
  def property_values_append(opts={})
    parent_select = Array( opts[:parent_select] )
    child_index = opts[:child_index]
    template = opts[:template]
    new_values = Array( opts[:values] )
    
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
    
    parent_nodeset = lookup(parent_select[0], parent_select[1])
    parent_node = node_from_set(parent_nodeset, child_index)
    
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
  
  def property_value_update(node_select,child_index,new_value,opts={})
    # template = opts.fetch(:template,nil)
    node = lookup(node_select, nil)[child_index]
    node.content = new_value
  end
  
  # def property_value_set(property_ref, query_opts, node_index, new_value)
  # end
  
  def property_value_delete(opts={})
    parent_select = Array( opts[:parent_select] )
    parent_index = opts[:parent_index]
    child_index = opts[:child_index]
    xpath_select = opts[:select]
    
    if !xpath_select.nil?
      node = lookup(xpath_select, nil).first
    else
      parent_nodeset = lookup(parent_select, parent_select)
      # parent_nodeset = lookup(parent_select[0])
      
      if parent_index.nil?
        node = node_from_set(parent_nodeset, child_index)
      else
        parent = node_from_set(parent_nodeset, parent_index)
        # this next line is a hack around the fact that element_children() sometimes doesn't work.
        node = node_from_set(parent.xpath("*"), child_index)
      end
    end
    
    node.remove
  end
   
  
  # Allows you to provide an array index _or_ a symbol representing the function to call on the nodeset in order to retrieve the node.
  def node_from_set(nodeset, index)
    if index.kind_of?(Integer)
      node = nodeset[index]
    elsif index.kind_of?(Symbol) && nodeset.respond_to?(index) 
      node = nodeset.send(index)
    else
      raise "Could not retrieve node using index #{index}."
    end
    
    return node
  end
  
  private :node_from_set
  
end