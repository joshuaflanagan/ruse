module Ruse
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
