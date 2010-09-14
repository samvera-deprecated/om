module OM::TreeNode
  
  attr_accessor :ancestors
  
  #  insert the mapper into the given parent
  def set_parent(parent_mapper)
    parent_mapper.children[@name] = self
    @ancestors << parent_mapper
  end
  
  #  insert the given mapper into the current mappers children
  def add_child(child_mapper)
    child_mapper.ancestors << self
    @children[child_mapper.name.to_sym] = child_mapper    
  end
  
  def retrieve_child(child_name)
    child = @children.fetch(child_name, nil)
  end
  
  def parent
    ancestors.last
  end
end
