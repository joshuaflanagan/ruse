require 'ruse/proc_resolver'
require 'ruse/class_loader'
require 'ruse/class_resolver'
require 'ruse/value_resolver'
require 'ruse/object_factory'

module Ruse
  class Auditor

    def begin_request(identifier, overrides)
      if current
        @current = current.add_child identifier, overrides
      else
        @current = Frame.new(identifier, overrides)
      end
    end

    def aliased(new_identifier)
      current.alias = new_identifier
    end

    def resolved_by(resolver)
      current.resolver = resolver
    end

    def resolved_to(instance)
      current.result = instance
      @previous = current
      @current = current.parent
    end

    def report(&block)
      @previous.report(&block)
    end

    private

    def current
      @current
    end

    class Frame
      attr_reader :identifier, :resolver, :result, :closed, :from_cache, :children
      attr_accessor :alias, :level, :parent

      def initialize(identifier, overrides, parent=nil)
        @parent = parent
        @identifier = identifier
        @overrides = overrides
        @from_cache = true
        @children = []
        @level = parent.nil? ? 0 : (parent.level + 1)
      end

      def report(&block)
        if block.nil?
          block = ->f{ f }
        end
        output = [block.call(self)]
        output << children.map{|c| c.report(&block)}
        output
      end

      def add_child(identifier, overrides)
        child = Frame.new(identifier, overrides, self)
        children.push child
        child
      end

      def to_s
        m = (" " * level) + "#{identifier.inspect}"
        m << " (-> #{self.alias.inspect})" if self.alias
        m << " resolved to #{result.inspect} by #{resolver}"
        m << "(cached)" if from_cache
        children.each {|c| m << "\n#{c.to_s}" }
        m
      end

      def resolved_by(value)
        @resolver = value
        @from_cache = false
      end

      def result=(value)
        @result = value
        @closed = true
      end
    end
  end

  class Injector
    def get(identifier, overrides=nil)
      auditor.begin_request(identifier, overrides)
      ensure_valid_identifier! identifier
      return get_with_overrides(identifier, overrides) if overrides

      aliased_as = aliases[identifier]
      if aliased_as
        identifier = aliased_as
        auditor.aliased(identifier)
      end
      resolved_value = cache_fetch(identifier) do
        resolver = find_resolver identifier
        raise UnknownServiceError.new(identifier) unless resolver
        auditor.resolved_by resolver
        resolver.build identifier
      end
      auditor.resolved_to(resolved_value)
      resolved_value
    rescue SystemStackError
      raise CircularDependency
    end

    def configure(settings)
      configuration.each do |setting_name, existing_values|
        merge_setting(existing_values, settings[setting_name])
      end
    end

    def can_resolve?(identifier)
      return false if invalid_identifier?(identifier)
      find_resolver(identifier)
    end

    private

    def auditor
      @auditor ||= Auditor.new
    end

    def get_with_overrides(identifier, overrides)
      request_injector = clone
      request_injector.configure(overrides)
      request_injector.get(identifier)
    end

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
        aliases: {},
        values: {},
        factories: {},
        namespaces: [],
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
      configuration[:namespaces]
    end

    def find_resolver(identifier)
      resolvers.detect {|r| r.can_build?(identifier) }
    end

    def resolvers
      @resolvers ||= [
        ProcResolver.new(factories),
        ValueResolver.new(values),
        ClassResolver.new(self, class_loader),
      ]
    end

    def class_loader
      if defined? ActiveSupport::Dependencies::ModuleConstMissing
        require "ruse/activesupport"
        ActiveSupportClassLoader.new(namespaces)
      else
        ClassLoader.new(namespaces)
      end
    end

    def merge_setting(existing, additions)
      case existing
      when Hash then existing.merge!(additions || {})
      when Array then (existing << (additions || [])).flatten!.uniq!
      else
        raise "Configuration values must be a Hash or Array"
      end
    end
  end

  class UnknownServiceError < StandardError; end
  class InvalidServiceName < StandardError; end
  class CircularDependency < StandardError; end
end
