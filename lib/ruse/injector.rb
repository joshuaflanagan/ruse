module Ruse
  class Injector
    def get(identifier)
      type = resolve_type identifier
      type.new
    end

    def resolve_type(identifier)
      Object.const_get identifier
    end
  end
end
