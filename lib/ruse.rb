require "ruse/injector"
require "ruse/version"

if defined? ActiveSupport::Dependencies::ModuleConstMissing
  require "ruse/activesupport"
end

module Ruse
  def self.create_injector(config=nil)
    Ruse::Injector.new.tap do |i|
      i.configure(config) if config
    end
  end
end
