require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/injector'

describe Ruse::Injector do
  def injector
    @injector ||= Ruse::Injector.new
  end

  it "retrieves instance when identifier is a class name" do
    injector.get("ServiceA").must_be_instance_of(ServiceA)
  end

  it "retrieves instance when identifier can be converted to a class name" do
    injector.get(:service_a).must_be_instance_of(ServiceA)
  end

  it "raises UnknownServiceError for an identifier it cannot resolve" do
    ->{
      injector.get("cannot_be_resolved")
    }.must_raise(Ruse::UnknownServiceError)
  end

  it "populates dependencies for the instance it retrieves" do
    instance = injector.get("ConsumerA")
    instance.must_be_instance_of(ConsumerA)
    instance.a.must_be_instance_of(ServiceA)
    instance.b.must_be_instance_of(ServiceB)
  end

  it "retrieves an instance based on a configured alias" do
    injector.configure special_service: "ServiceA"
    injector.get(:special_service).must_be_instance_of(ServiceA)
  end

  it "returns same instance of a given service within a single request" do
    instance = injector.get("ConsumerC")
    instance.ca.a.must_be_same_as(instance.cb.a)
  end

  it "returns same instance of a given service for life of injector" do
    instance1 = injector.get("ConsumerC")
    instance2 = injector.get("ConsumerC")
    instance1.must_be_same_as(instance2)
  end

  it "returns different instance of given service for different injectors" do
    instance1 = Ruse::Injector.new.get("ConsumerC")
    instance2 = Ruse::Injector.new.get("ConsumerC")
    instance1.wont_be_same_as(instance2)
  end

  class ServiceA; end
  class ServiceB; end

  class ConsumerA
    attr_reader :a, :b
    def initialize(service_a, service_b)
      @a = service_a
      @b = service_b
    end
  end

  class ConsumerB
    attr_reader :a
    def initialize(service_a)
      @a = service_a
    end
  end

  class ConsumerC
    attr_reader :ca, :cb
    def initialize(consumer_a, consumer_b)
      @ca = consumer_a
      @cb = consumer_b
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
