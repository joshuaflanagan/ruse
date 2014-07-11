require "ruse/injector"
require "ruse/version"

module Ruse
  def self.create_injector(config=nil)
    Ruse::Injector.new.tap do |i|
      i.configure(config) if config
    end
  end
end
