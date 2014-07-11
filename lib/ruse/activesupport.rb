module Ruse
  class ActiveSupportClassLoader < ClassLoader
    def load_type(type_name)
      type_name.safe_constantize
    end
  end
end
