lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kanoko/version"

Gem::Specification.new do |spec|
  spec.name          = "kanoko"
  spec.version       = Kanoko::VERSION
  spec.authors       = ["ksss"]
  spec.email         = ["co000ri@gmail.com"]
  spec.summary       = %q{kanoko is a active image generater library.}
  spec.description   = %q{kanoko is a active image generater library.}
  spec.homepage      = "https://github.com/spice-life/kanoko"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "exifr"
end
