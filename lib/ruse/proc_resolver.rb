class ProcResolver
  attr_reader :factories
  def initialize(factories)
    @factories = factories
  end
  def can_build?(identifier)
    factories.key? identifier
  end

  def build(identifier)
    factory = factories.fetch(identifier)
    factory.call
  end
end
