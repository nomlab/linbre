# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'linbre/version'

Gem::Specification.new do |spec|
  spec.name          = "linbre"
  spec.version       = Linbre::VERSION
  spec.authors       = ["Yoshinari Nomura and Nomura Laboratory"]
  spec.email         = ["nom@quickhack.net"]

  spec.summary       = %q{The Knuth/Plass line-breaking algorithm in Ruby.}
  spec.description   = %q{The Knuth/Plass line-breaking algorithm in Ruby. Ported from https://github.com/bramstein/typeset/}
  spec.homepage      = "https://github.com/nomlab/linbre/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
