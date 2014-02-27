module Ruse
  class Injector
    def get(identifier)
      identifier = aliases[identifier] || identifier
      cache_fetch(identifier) do
        resolver = find_resolver identifier
        raise UnknownServiceError.new(identifier) unless resolver
        resolver.build identifier
      end
    end

    def configure(settings)
      configuration.merge! settings
    end

    private

    def cache_fetch(identifier, &block)
      return cache[identifier] if cache.key?(identifier)
      cache[identifier] = block.call
    end

    def cache
      @cache ||= {}
    end

    def configuration
      @configuration ||= { aliases:{} }
    end

    def aliases
      configuration[:aliases]
    end

    def find_resolver(identifier)
      resolvers.detect {|h|
        h.can_build?(identifier)
      }
    end

    def resolvers
      @resolvers ||= [
        TypeResolver.new(self),
      ]
    end
  end

  class UnknownServiceError < StandardError; end

  class TypeResolver
    def initialize(injector)
      @injector = injector
    end

    def can_build?(identifier)
      type_name = self.class.classify(identifier)
      Object.const_defined?(type_name)
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

    def object_factory
      @object_factory ||= ObjectFactory.new(@injector)
    end

    def resolve_type(identifier)
      type_name = self.class.classify(identifier)
      Object.const_get type_name
    end
  end

  class ObjectFactory
    attr_reader :injector

    def initialize(injector)
      @injector = injector
    end

    def build(type)
      args = resolve_dependencies type
      type.new *args
    end

    private

    def resolve_dependencies(type)
      type.instance_method(:initialize).parameters.map{|_, identifier|
        @injector.get identifier
      }
    end
  end
end
