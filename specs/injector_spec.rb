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

  it "retrieves instance when identifier can be converted to a class in registered namespace" do
    injector.configure namespaces: {"Unused" => true, "Deep::Namespaced" => true}
    injector.get("Service").
      must_be_instance_of(Deep::Namespaced::Service)
  end

  it "raises UnknownServiceError for an identifier it cannot resolve" do
    ->{
      injector.get("cannot_be_resolved")
    }.must_raise(Ruse::UnknownServiceError)
  end

  it "raises CircularDependency when appropriate" do
    ->{
      injector.get("circular_a")
    }.must_raise(Ruse::CircularDependency)
  end

  it "raises InvalidServiceName when identifier is nil" do
    ->{
      injector.get(nil)
    }.must_raise(Ruse::InvalidServiceName)
  end

  it "raises InvalidServiceName when identifier is blank string" do
    ->{
      injector.get(" ")
    }.must_raise(Ruse::InvalidServiceName)
  end

  it "cannot resolve a nil identifier" do
    refute injector.can_resolve?(nil)
  end

  it "cannot resolve a blank string identifier" do
    refute injector.can_resolve?(" ")
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

  it "can be reconfigured" do
    injector.configure(values: { service_a: 'foo' })
    injector.configure(values: { service_b: 'bar' })
    object = injector.get(:consumer_a)
    object.a.must_equal 'foo'
    object.b.must_equal 'bar'
  end

  it "duplicates configuration on cloning" do
    injector.configure(values: { service_a: 'foo', service_b: 'bar' })
    child_injector = injector.clone
    child_injector.configure(values: { service_a: 'FOO' })
    child_object = child_injector.get(:consumer_a)
    parent_object = injector.get(:consumer_a)

    child_object.a.must_equal 'FOO'
    parent_object.a.must_equal 'foo'
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
end

class CircularA
  def initialize(circular_b); end
end

class CircularB
  def initialize(circular_a); end
end
