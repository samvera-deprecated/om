# Term::Builder Class Definition
#
# @example
#   tb2 = OM::XML::Term::Builder.new("my_term_name").path("fooPath").attributes({:lang=>"foo"}).index_as([:searchable, :facetable]).required(true).type(:text)
#
#
#
# When coding against Builders, remember that they rely on MethodMissing,
# so any time you call a method on the Builder that it doesn't explicitly recognize,
# the Builder will add your method & arguments to the it's settings and return itself.
#
module OM::XML::TermBuilder
  class Builder
    attr_accessor :name, :settings, :children, :terminology_builder

    def initialize(name, terminology_builder=nil)
      @name = name.to_sym
      @terminology_builder = terminology_builder
      @settings = {:required=>false, :type=>:string}
      @children = {}
    end

    def add_child(child)
      @children[child.name] = child
    end

    def retrieve_child(child_name)
      child = @children.fetch(child_name, nil)
    end

    def lookup_refs(nodes_visited=[])
      result = []
      if @settings[:ref]
        # Fail if we do not have terminology builder
        if self.terminology_builder.nil?
          raise "Cannot perform lookup_ref for the #{self.name} builder.  It doesn't have a reference to any terminology builder"
        end
        target = self.terminology_builder.retrieve_term_builder(*@settings[:ref])

        # Fail on circular references and return an intelligible error message
        if nodes_visited.include?(target)
          nodes_visited << self
          nodes_visited << target
          trail = ""
          nodes_visited.each_with_index do |node, z|
            trail << node.name.inspect
            unless z == nodes_visited.length-1
              trail << " => "
            end
          end
          raise OM::XML::Terminology::CircularReferenceError, "Circular reference in Terminology: #{trail}"
        end
        result << target
        result.concat( target.lookup_refs(nodes_visited << self) )
      end
      return result
    end

    # If a :ref value has been set, looks up the target of that ref and merges the target's settings & children with the current builder's settings & children
    # operates recursively, so it is possible to apply refs that in turn refer to other nodes.
    def resolve_refs!
      name_of_last_ref = nil
      lookup_refs.each_with_index do |ref,z|
        @settings = two_layer_merge(@settings, ref.settings)
        @children.merge!(ref.children)
        name_of_last_ref = ref.name
      end
      if @settings[:path].nil? && !name_of_last_ref.nil?
        @settings[:path] = name_of_last_ref.to_s
      end
      @settings.delete :ref
      return self
    end

    # Returns a new Hash that merges +downstream_hash+ with +upstream_hash+
    # similar to calling +upstream_hash+.merge(+downstream_hash+) only it also merges
    # any internal values that are themselves Hashes.
    def two_layer_merge(downstream_hash, upstream_hash)
      up = upstream_hash.dup
      dn = downstream_hash.dup
      up.each_pair do |setting_name, value|
        if value.kind_of?(Hash) && downstream_hash.has_key?(setting_name)
          dn[setting_name] = value.merge(downstream_hash[setting_name])
          up.delete(setting_name)
        end
      end
      return up.merge(dn)
    end

    # Builds a new OM::XML::Term based on the Builder object's current settings
    # If no path has been provided, uses the Builder object's name as the term's path
    # Recursively builds any children, appending the results as children of the Term that's being built.
    # @param [OM::XML::Terminology] terminology that this Term is being built for
    def build(terminology=nil)
      self.resolve_refs!
      if settings.has_key?(:proxy)
        term = OM::XML::NamedTermProxy.new(self.name, self.settings[:proxy], terminology, self.settings)
      else
        term = OM::XML::Term.new(self.name, {}, terminology)

        self.settings.each do |name, values|
          if term.respond_to?(name.to_s+"=")
            term.instance_variable_set("@#{name}", values)
          end
        end
        @children.each_value do |child|
          term.add_child child.build(terminology)
        end
        term.generate_xpath_queries!
      end

      return term
    end

    # We have to add this method so it will play nice with ruby 1.8.7
    def type value
      @settings[:type] = value
      return self
    end

    def root_term= val
      @settings[:is_root_term] = val
    end

    def index_as= val
      @settings[:index_as] = val
    end

    def required= val
      @settings[:required] = val
    end

    def ref= val
      @settings[:ref] = val
    end

    def attributes= val
      @settings[:attributes] = val
    end

    def proxy= val
      @settings[:proxy] = val
    end

    def type= val
      @settings[:type] = val
    end

    def path= val
      @settings[:path] = val
    end

    def variant_of= val
      @settings[:variant_of] = val
    end

    def default_content_path= val
      @settings[:default_content_path] = val
    end

  end
end
