require File.join(File.dirname(__FILE__), "lib/geomdtk/version")

Gem::Specification.new do |s|
  s.name = "geomdtk"
  s.version = GeoMDTK::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">=1.9.3"
  s.authors = ["Darren Hardy"]
  s.email = ["drh@stanford.edu"]
  s.summary = %q{GeoMDTK}
  s.description = %q{Geospatial MetaData ToolKit for use in a GeoHydra head}
  s.has_rdoc = true
  s.licenses = ['ALv2', 'Stanford University Libraries']
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "confstruct"
  s.add_dependency "nokogiri"
  s.add_dependency "rest-client"

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
  s.add_development_dependency "rdoc" # provides Markdown
  
end
