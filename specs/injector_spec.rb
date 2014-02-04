require 'minitest/spec'
require 'minitest/autorun'
require 'ruse/injector'

describe Ruse::Injector do
  it "retrieves an instance it can infer from an identifier" do
    injector = Ruse::Injector.new
    injector.get("SomeService").must_be_instance_of(SomeService)
  end
  class SomeService; end
end
