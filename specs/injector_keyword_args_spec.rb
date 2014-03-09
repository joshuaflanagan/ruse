require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/injector'

describe Ruse::Injector do
  def injector
    @injector ||= Ruse::Injector.new
  end

  it "injects keyword arguments it can resolve, delegating to defaults when it can't" do
    skip("No keyword argument support before Ruby 2.0") unless RUBY_VERSION >= "2.0"
    object = injector.get("HasKeywordArguments")
    object.a.must_be_kind_of ServiceA
    object.z.must_equal :z
  end

  it "injects optional parameters it can resolve, delegating to defaults when it can't" do
    skip("No keyword argument support before Ruby 2.0") unless RUBY_VERSION >= "2.0"
    object = injector.get("HasOptionalParameters")
    object.a.must_be_kind_of ServiceA
    object.z.must_equal :z
  end

  it "injects required keyword arguments" do
    skip("No required keyword argument support before Ruby 2.1") unless RUBY_VERSION >= "2.1"
    object = injector.get("HasRequiredKeywordArguments")
    object.a.must_be_kind_of ServiceA
  end

  it "exceptions when a required keyword argument can't resolve" do
    skip("No required keyword argument support before Ruby 2.1") unless RUBY_VERSION >= "2.1"
    -> {
      injector.get("HasUnresolvableRequiredKeywordArguments")
    }.must_raise Ruse::UnknownServiceError
  end

  class ServiceA; end

  if RUBY_VERSION >= "2.0"
    class HasOptionalParameters
      attr_reader :a, :z
      class_eval <<-EVAL, __FILE__, __LINE__
    def initialize(service_a = :a, service_z = :z)
      @a = service_a
      @z = service_z
    end
      EVAL
    end

    class HasKeywordArguments
      attr_reader :a, :z
      class_eval <<-EVAL, __FILE__, __LINE__
    def initialize(service_a: :a, service_z: :z)
      @a = service_a
      @z = service_z
    end
      EVAL
    end
  end
  if RUBY_VERSION >= "2.1"
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
end
