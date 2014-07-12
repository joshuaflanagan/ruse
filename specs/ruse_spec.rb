require 'minitest/spec'
require 'minitest/autorun'
require 'ruse'

describe Ruse do
  it "can create an injector" do
    Ruse.create_injector.must_be_kind_of Ruse::Injector
  end

  it "passes configuration to the injector" do
    injector = Ruse.create_injector(values: { answer: 42 })
    injector.get(:answer).must_equal 42
  end
end
