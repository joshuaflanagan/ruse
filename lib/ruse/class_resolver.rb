module Ruse
  class ClassResolver
    attr_reader :class_loader

    def initialize(injector, class_loader)
      @injector = injector
      @class_loader = class_loader
    end

    def can_build?(identifier)
      resolve_type identifier
    end

    def build(identifier)
      type = resolve_type identifier
      object_factory.build(type)
    end

    private

    def object_factory
      @object_factory ||= ObjectFactory.new(@injector)
    end

    def resolve_type(identifier)
      class_loader.load identifier
    end
  end
end
