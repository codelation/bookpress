# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bookpress/version'

Gem::Specification.new do |spec|
  spec.name          = "bookpress"
  spec.version       = Bookpress::VERSION
  spec.authors       = ["Matthew Sullivan"]
  spec.email         = ["msull92@gmail.com"]
  spec.summary       = %q{Bookpress is a small gem that spits out a single HTML document, generated
                          from an implicit directory structure of markdown files.}
  spec.homepage      = "https://github.com/msull92/bookpress"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "nokogiri"
  spec.add_dependency "redcarpet"
  spec.add_dependency "pygments.rb"
  spec.add_dependency "aws-s3"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
