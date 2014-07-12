require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/class_loader'

describe Ruse::ClassLoader do
  describe "classify" do
    it "converts an underscored_term to PascalCase" do
      resolver = Ruse::ClassLoader.new
      resolver.classify("camel_case").must_equal("CamelCase")
    end

    it "echoes back a PascalCase term" do
      resolver = Ruse::ClassLoader.new
      resolver.classify("PascalCase").must_equal("PascalCase")
    end
  end
end
