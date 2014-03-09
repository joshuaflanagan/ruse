# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruse/version'

Gem::Specification.new do |spec|
  spec.name          = "ruse"
  spec.version       = Ruse::VERSION
  spec.authors       = ["Joshua Flanagan"]
  spec.email         = ["joshuaflanagan@gmail.com"]
  spec.summary       = %q{Ruse}
  spec.description   = %q{Ruse}
  spec.homepage      = "https://github.com/joshuaflanagan/ruse"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
