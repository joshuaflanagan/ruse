module Ruse
  class ObjectFactory
    attr_reader :injector

    def initialize(injector)
      @injector = injector
    end

    def build(type)
      initializer = Initializer.new @injector, type.instance_method(:initialize)
      initializer.resolve_dependencies!
      type.new *initializer.args
    end

    class Initializer
      attr_reader :positional_args, :keyword_args

      def initialize(injector, initialize_method)
        @injector          = injector
        @initialize_method = initialize_method
        @positional_args   = []
        @keyword_args      = {}
      end

      def args
        [*positional_args, **keyword_args].tap do |list|
          list.pop if list.last.empty?
        end
      end

      def resolve_dependencies!
        @initialize_method.parameters.each do |arg_type, identifier|
          MethodArgument.build(arg_type, identifier, @injector).resolve(self)
        end
      end

      MethodArgument = Struct.new :arg_type, :identifier, :injector do
        def self.build(arg_type, *args)
          [PositionalArgument, KeywordArgument].each do |klass|
            return klass.new(arg_type, *args) if klass.match?(arg_type)
          end
          UnhandleableArgument
        end

        def build_dependency
          injector.get identifier
        end

        def must_resolve?
          required? || injector.can_resolve?(identifier)
        end

        def resolve(initializer)
          resolve!(initializer) if must_resolve?
        end
      end

      class PositionalArgument < MethodArgument
        def self.match?(arg_type)
          [:req, :opt].include? arg_type
        end

        def required?
          arg_type == :req
        end

        def resolve!(initializer)
          initializer.positional_args << build_dependency
        end
      end

      class KeywordArgument < MethodArgument
        def self.match?(arg_type)
          [:key, :keyreq].include? arg_type
        end

        def required?
          arg_type == :keyreq
        end

        def resolve!(initializer)
          initializer.keyword_args[identifier] = build_dependency
        end
      end

      # Singleton object that be substituted for the other MethodArgument
      # subclasses when we don't want to try resolving the argument.
      module UnhandleableArgument
        extend self
        def resolve(*) end
      end
    end
  end
end
