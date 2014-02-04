require "ruse/injector"
require "ruse/version"

module Ruse
  def self.create_injector
    Ruse::Injector.new
  end
end
