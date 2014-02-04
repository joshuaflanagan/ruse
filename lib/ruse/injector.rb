module Ruse
  class Injector
    def get(identifier)
      type = resolve_type identifier
      args = resolve_dependencies type
      type.new *args
    end

    def resolve_type(identifier)
      type_name = classify(identifier)
      unless Object.const_defined?(type_name)
        raise UnknownServiceError.new(type_name)
      end
      Object.const_get type_name
    end

    def resolve_dependencies(type)
      type.instance_method(:initialize).parameters.map{|_, identifier|
        get identifier
      }
    end

    def classify(term)
      # lifted from active_support gem: lib/active_support/inflector/methods.rb
      string = term.to_s
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string.gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{ $2.capitalize}" }.gsub('/', '::')
    end
  end

  class UnknownServiceError < StandardError; end
end
