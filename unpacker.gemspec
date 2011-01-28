# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "unpacker/version"

Gem::Specification.new do |s|
  s.name        = "unpacker"
  s.version     = Unpacker::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Linus Oleander"]
  s.email       = ["linus@oleander.nu"]
  s.homepage    = ""
  s.summary     = %q{An automated unrar gem}
  s.description = %q{Unpack rar and zip files in a certain directory}

  s.rubyforge_project = "unpacker"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency('rspec')
end
