module Ruse
  # Eventually, the resolvers may be pluggable, in which case we could
  # replace the normal TypeResolver with one specific to ActiveSupport.
  # For now, we'll just monkeypatch.
  class TypeResolver
    def load_type(type_name)
      type_name.safe_constantize
    end
  end
end
