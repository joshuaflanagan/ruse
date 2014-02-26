require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/injector'

describe Ruse::Injector do
  it "retrieves an instance it can infer from an identifier" do
    injector = Ruse::Injector.new
    injector.get("SomeService").must_be_instance_of(SomeService)
  end

  it "raises UnknownServiceError for an identifier it cannot resolve" do
    injector = Ruse::Injector.new
    ->{
      injector.get("cannot_be_resolved")
    }.must_raise(Ruse::UnknownServiceError)
  end

  it "populates dependencies for the instance it retrieves" do
    injector = Ruse::Injector.new
    instance = injector.get("ServiceConsumer")
    instance.must_be_instance_of(ServiceConsumer)
    instance.service1.must_be_instance_of(SomeService)
    instance.service2.must_be_instance_of(OtherService)
  end

  class SomeService; end
  class OtherService; end

  class ServiceConsumer
    attr_reader :service1, :service2
    def initialize(some_service, other_service)
      @service1 = some_service
      @service2 = other_service
    end
  end
end

describe "classify" do
  it "converts an underscored_term to PascalCase" do
    resolver = Ruse::TypeResolver
    resolver.classify("camel_case").must_equal("CamelCase")
  end

  it "echoes back a PascalCase term" do
    resolver = Ruse::TypeResolver
    resolver.classify("PascalCase").must_equal("PascalCase")
  end
end
