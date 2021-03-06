# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dover_to_calais/version'

Gem::Specification.new do |spec|
  spec.name          = "dover_to_calais"
  spec.version       = DoverToCalais::VERSION
  spec.authors       = ["Fred Heath"]
  spec.email         = ["fred_h@bootstrap.me.uk"]
  spec.description   = %q{DoverToCalais allows the user to send a wide range of data sources (files & URLs)
                          to OpenCalais and receive asynchronous responses when OpenCalais has finished processing
                          the inputs. In addition, DoverToCalais enables the filtering of the response in order to
                          find relevant tags and/or tag values. }
  spec.summary       = %q{An easy-to-use wrapper round the OpenCalais semantic analysis web service. }
  spec.homepage      = "https://github.com/RedFred7/dover_to_calais"
  spec.license       = "MIT"


  spec.add_runtime_dependency "nokogiri", "~> 1.6"
  spec.add_runtime_dependency "eventmachine", "~> 1.0", ">= 1.0.3"
  spec.add_runtime_dependency "em-http-request", "~> 1.1"
  spec.add_runtime_dependency "yomu", "~> 0.1", ">= 0.1.9"
  spec.add_runtime_dependency "json", "~> 1.5", ">= 1.5.5"
  spec.add_runtime_dependency "ohm", "~> 2.0", ">= 2.0.0"
  spec.add_runtime_dependency "ohm-contrib", "~> 2.0", ">= 2.0.0"
  spec.add_runtime_dependency "em-throttled_queue", "~> 1.1", ">= 1.1.0"


  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 0"
  spec.add_development_dependency "cucumber", "~> 1.3", ">= 1.3.8"
  spec.add_development_dependency "rspec", "~> 2.14", ">= 2.14.1"
end
