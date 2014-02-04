require 'minitest/spec'
require 'minitest/autorun'
require 'ruse'

describe Ruse do
  it "can create an injector" do
    Ruse.create_injector.must_be_kind_of Ruse::Injector
  end
end
