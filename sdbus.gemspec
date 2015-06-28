# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sdbus/version'

Gem::Specification.new do |spec|
  spec.name          = 'sdbus'
  spec.version       = Sdbus::VERSION
  spec.authors       = ['John Ledbetter']
  spec.email         = ['john@throttle.io']

  spec.summary       = %q{Ruby bindings for the sd-bus dbus/kdbus library.}
  spec.description   = %q{Ruby bindings for the sd-bus dbus/kdbus library.}
  spec.homepage      = "https://github.com/ledbettj/sdbus"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ffi', '~> 1.9.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'rubocop'

end
