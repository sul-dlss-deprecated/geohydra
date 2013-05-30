Gem::Specification.new do |s|
  s.name = "geomdtk"
  s.version = 0.1
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">=1.9.3"
  s.authors = ["Darren Hardy"]
  s.email = ["drh@stanford.edu"]
  s.summary = %q{GeoMDTK}
  s.description = %q{Geo MetaData ToolKit}
  s.has_rdoc = true
  s.licenses = ['ALv2', 'Stanford University Libraries']
  

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {examples,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri"
  s.add_dependency "rest-client"
  s.add_dependency "lyber-core"
  s.add_dependency "mods"

  s.add_development_dependency("rspec")
  s.add_development_dependency("awesome_print")
end
