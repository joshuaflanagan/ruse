module Ruse
  class ClassLoader
    def initialize(namespaces=[])
      @namespaces = namespaces
    end

    def load(identifier)
      type_name = classify(identifier)
      try_load_type type_name
    end

    def classify(term)
      # lifted from active_support gem: lib/active_support/inflector/methods.rb
      string = term.to_s
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string.gsub(/(?:_|(\/))([a-z\d]*)/i) {
        "#{Regexp.last_match[1]}#{ Regexp.last_match[2].capitalize}"
      }.gsub('/', '::')
    end

    private

    attr_reader :namespaces

    def base_module
      Object
    end

    def try_load_type(type_name)
      loaded = load_type(type_name)
      return loaded if loaded
      namespaces.each do |ns|
        loaded = load_type "#{ns}::#{type_name}"
        return loaded if loaded
      end
      nil
    end

    def load_type(type_name)
      type_name.split('::').reduce(base_module) {|ns, name|
        return nil if ns.nil?
        ns.const_get(name) if ns.const_defined?(name)
      }
    end
  end
end
