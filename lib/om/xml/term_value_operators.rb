require "open-uri"
require "logger"

class OM::XML::ParentNodeNotFoundError < RuntimeError; end
module OM::XML::TermValueOperators
  
  def term_values(*lookup_args)
    result = []
    find_by_terms(*lookup_args).each {|node| result << node.text }
    return result
  end
  
  # 
  # example term values hash: {[{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}, [{:person=>1}, :family_name]=>"Andronicus", [{"person"=>"1"},:given_name]=>["Titus"],[{:person=>1},:role,:text]=>["otherrole1","otherrole2"] }
  def update_values(params={})
    # remove any terms from params that this datastream doesn't recognize    
    
    params.delete_if do |term_pointer,new_values| 
      if term_pointer.kind_of?(String)
        true
      else
        !self.class.terminology.has_term?(*OM.destringify(term_pointer))
        # self.class.terminology.xpath_with_indexes(*OM.destringify(field_key) ).nil?
      end
    end
    
    result = params.dup
    
    params.each_pair do |term_pointer,new_values|
      pointer = OM.destringify(term_pointer)
      template = OM.pointers_to_flat_array(pointer,false)
      hn = OM::XML::Terminology.term_hierarchical_name(*pointer)
      
      case new_values
      when Hash
      when Array
        nv = new_values.dup
        new_values = {}
        nv.each {|v| new_values[nv.index(v).to_s] = v}
      else
        new_values = {"0"=>new_values}
      end
      
      result.delete(term_pointer)
      result[hn] = new_values.dup
      
      current_values = term_values(*pointer)
      new_values.delete_if do |y,z| 
        if current_values[y.to_i]==z and y.to_i > -1
          true
        else
          false
        end
      end 
      xpath = self.class.terminology.xpath_with_indexes(*pointer)
      parent_pointer = pointer.dup
      parent_pointer.pop
      parent_xpath = self.class.terminology.xpath_with_indexes(*parent_pointer)
      new_values.each do |y,z|         
        if find_by_terms(*pointer)[y.to_i].nil? || y.to_i == -1
          result[hn].delete(y)
          term_values_append(:parent_select=>parent_xpath,:child_index=>0,:template=>template,:values=>z)
          new_array_index = find_by_terms(*pointer).length - 1
          result[hn][new_array_index.to_s] = z
        else
          term_value_update(xpath, y.to_i, z)
        end
      end
    end
    return result
  end
  
  def term_values_append(opts={})
    parent_select = Array( opts[:parent_select] )
    child_index = opts[:child_index]
    template = opts[:template]
    new_values = Array( opts[:values] )
  
    # If template is a string, use it as the template, otherwise use it as arguments to xml_builder_template
    unless template.instance_of?(String)
      template_args = Array(template)
      if template_args.last.kind_of?(Hash)
        template_opts = template_args.delete_at(template_args.length - 1)
        template_args << template_opts
      end
      
      template = self.class.terminology.xml_builder_template( *template_args )
    end    
    
    # parent_nodeset = find_by_terms_and_value(parent_select[0], parent_select[1])
    parent_nodeset = find_by_terms(*parent_select)
    parent_node = node_from_set(parent_nodeset, child_index)
    
    if parent_node.nil?
      raise OM::XML::ParentNodeNotFoundError, "Failed to find a parent node to insert values into based on :parent_select #{parent_select.inspect} with :child_index #{child_index.inspect}"
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
  
  def term_value_update(node_select,child_index,new_value,opts={})
    # template = opts.fetch(:template,nil)
    node = find_by_terms_and_value(node_select)[child_index]
    node.content = new_value
  end
  
  # def term_value_set(term_ref, query_opts, node_index, new_value)
  # end
  
  def term_value_delete(opts={})
    parent_select = Array( opts[:parent_select] )
    parent_index = opts[:parent_index]
    child_index = opts[:child_index]
    xpath_select = opts[:select]
    
    if !xpath_select.nil?
      node = find_by_terms_and_value(xpath_select).first
    else
      # parent_nodeset = find_by_terms_and_value(parent_select, parent_select)
      parent_nodeset = find_by_terms_and_value(*parent_select)
      
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