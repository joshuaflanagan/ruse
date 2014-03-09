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

  it "retrieves instance when identifier is namespaced class name" do
    injector.get("Deep::Namespaced::Service").
      must_be_instance_of(Deep::Namespaced::Service)
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
    injector.configure aliases: {special_service: "ServiceA"}
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

  it "can retrieve a registered value object" do
    value_object = Object.new
    injector.configure values: { example: value_object }
    injector.get(:example).must_be_same_as(value_object)
  end

  it "can retrieve an object via delayed evaluation" do
    the_value = 42
    injector.configure factories: { example: -> { Delayed.new(the_value) } }
    the_value = 88
    instance = injector.get(:example)
    instance.must_be_instance_of(Delayed)
    instance.value.must_equal(88)
  end

  it "skips over splats" do
    injector.get("HasSplatInInitializer").must_be_kind_of HasSplatInInitializer
    injector.get("Array").must_equal []
  end

  it "injects optional parameters it can resolve, delegating to defaults when it can't" do
    object = injector.get("HasOptionalParameters")
    object.a.must_be_kind_of ServiceA
    object.z.must_equal :z
  end

  it "injects keyword arguments it can resolve, delegating to defaults when it can't" do
    object = injector.get("HasKeywordArguments")
    object.a.must_be_kind_of ServiceA
    object.z.must_equal :z
  end

  if RUBY_VERSION >= "2.1"
    it "injects required keyword arguments" do
      object = injector.get("HasRequiredKeywordArguments")
      object.a.must_be_kind_of ServiceA
    end
    it "exceptions when a required keyword argument can't resolve" do
      -> {
        injector.get("HasUnresolvableRequiredKeywordArguments")
      }.must_raise Ruse::UnknownServiceError
    end

    class HasRequiredKeywordArguments
      attr_reader :a
      class_eval <<-EVAL, __FILE__, __LINE__
      def initialize(service_a:)
        @a = service_a
      end
      EVAL
    end
    class HasUnresolvableRequiredKeywordArguments
      class_eval <<-EVAL, __FILE__, __LINE__
      def initialize(service_z:) end
      EVAL
    end
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

  class Delayed
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  module Deep
    module Namespaced
      class Service
      end
    end
  end

  class HasSplatInInitializer
    def initialize(*args)
    end
  end

  class HasOptionalParameters
    attr_reader :a, :z
    def initialize(service_a = :a, service_z = :z)
      @a = service_a
      @z = service_z
    end
  end

  class HasKeywordArguments
    attr_reader :a, :z
    def initialize(service_a: :a, service_z: :z)
      @a = service_a
      @z = service_z
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
