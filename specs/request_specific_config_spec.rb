require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/injector'

describe "Providing request-specific configuration" do
  def injector
    @injector ||= Ruse::Injector.new
  end

  it "supports overwriting configured values" do
    injector.configure aliases: { service: "RscService1" }

    instance = injector.get(:service, aliases: { service: "RscService2" })
    instance.must_be_instance_of(RscService2)
  end

  it "supports adding new values" do
    instance = injector.get(:service, aliases: { service: "RscService2" })
    instance.must_be_instance_of(RscService2)
  end

  it "does not change the injector for subsequent requests" do
    injector.configure aliases: { service: "RscService1" }

    instance = injector.get(:service, aliases: { service: "RscService2" })
    instance.must_be_instance_of(RscService2)

    instance = injector.get(:service)
    instance.must_be_instance_of(RscService1)
  end

  class RscService1
  end

  class RscService2
  end
end
