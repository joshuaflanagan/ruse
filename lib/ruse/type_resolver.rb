module Ruse
  class TypeResolver
    def initialize(injector)
      @injector = injector
    end

    def can_build?(identifier)
      type_name = self.class.classify(identifier)
      try_load_type type_name
    end

    def build(identifier)
      type = resolve_type identifier
      object_factory.build(type)
    end

    def self.classify(term)
      # lifted from active_support gem: lib/active_support/inflector/methods.rb
      string = term.to_s
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string.gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{ $2.capitalize}" }.gsub('/', '::')
    end

    private

    def namespaces
      #TODO: fix when a build session is available with current config
      @injector.__send__(:namespaces)
    end

    def base_module
      Object
    end

    def try_load_type(type_name)
      loaded = load_type(type_name)
      return loaded if loaded
      if loaded
        return loaded
      end
      namespaces.each do |ns|
        loaded = load_type "#{ns}::#{type_name}"
        return loaded if loaded
      end
      nil
    end

    def load_type(type_name)
      type_name.split('::').reduce(base_module){|ns, name|
        return nil if ns.nil?
        if ns.const_defined? name
          ns.const_get name
        end
      }
    end

    def object_factory
      @object_factory ||= ObjectFactory.new(@injector)
    end

    def resolve_type(identifier)
      type_name = self.class.classify(identifier)
      try_load_type type_name
    end
  end
end
