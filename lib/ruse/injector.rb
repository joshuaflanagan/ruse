require 'ruse/proc_resolver'
require 'ruse/type_resolver'
require 'ruse/value_resolver'
require 'ruse/object_factory'

module Ruse
  class Injector
    def get(identifier)
      ensure_valid_identifier! identifier
      identifier = aliases[identifier] || identifier
      cache_fetch(identifier) do
        resolver = find_resolver identifier
        raise UnknownServiceError.new(identifier) unless resolver
        resolver.build identifier
      end
    rescue SystemStackError
      fail CircularDependency
    end

    def configure(settings)
      configuration.each do |key, hsh|
        hsh.merge!(settings[key] || {})
      end
    end

    def can_resolve?(identifier)
      return false if invalid_identifier?(identifier)
      find_resolver(identifier) ? true : false
    end

    private

    def ensure_valid_identifier!(identifier)
      if invalid_identifier? identifier
        raise InvalidServiceName.new("<#{identifier.inspect}>")
      end
    end

    def invalid_identifier?(identifier)
      identifier.nil? || empty_string?(identifier)
    end

    def empty_string?(s)
      s.is_a?(String) && s !~ /[^[:space:]]/
    end

    def cache_fetch(identifier, &block)
      return cache[identifier] if cache.key?(identifier)
      cache[identifier] = block.call
    end

    def cache
      @cache ||= {}
    end

    def configuration
      @configuration ||= {
       aliases:{},
       values: {},
       factories: {},
       namespaces: {}
      }
    end

    def reset_configuration
      @configuration = nil
    end
    # Allow #initialize_clone to reset the configuration of the cloned injector
    protected :reset_configuration

    def initialize_clone(cloned_injector)
      cloned_injector.reset_configuration
      cloned_injector.configure(configuration)
    end

    def aliases
      configuration[:aliases]
    end

    def values
      configuration[:values]
    end

    def factories
      configuration[:factories]
    end

    def namespaces
      #TODO: support storing array in configuration
      configuration[:namespaces].keys
    end

    def find_resolver(identifier)
      resolvers.detect {|h|
        h.can_build?(identifier)
      }
    end

    def resolvers
      @resolvers ||= [
        ProcResolver.new(factories),
        ValueResolver.new(values),
        TypeResolver.new(self),
      ]
    end
  end

  class UnknownServiceError < StandardError; end
  class InvalidServiceName < StandardError; end
  class CircularDependency < StandardError; end
end
