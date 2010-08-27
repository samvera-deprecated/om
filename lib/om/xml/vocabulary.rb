class OM::XML::Vocabulary
  
  attr_accessor :builder
  # Vocabularies are not editable once they've been created because inserting/removing/rearranging mappers in a vocabulary 
  # will invalidate the xpath queries for an entire branch of the Vocabulary's tree of mappers.
  # If you want to change a vocabulary's structure, retrieve it's +builder+, make your changes, and re-generate the vocabulary.
  # 
  # Ex:
  #   builder = vocabulary.builder
  #   builder.insert_mapper(:name_, :namePart)
  #   vocabulary = builder.build
  
  # Mappers can be retrieved by their mapper name
  # Ex.
  # vocabulary.retrieve_mapper(:name_, :namePart)

end