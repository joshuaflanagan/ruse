module Ruse
  class ValueResolver
    attr_reader :values

    def initialize(values)
      @values = values
    end

    def can_build?(identifier)
      values.key? identifier
    end

    def build(identifier)
      values.fetch(identifier)
    end
  end
end
