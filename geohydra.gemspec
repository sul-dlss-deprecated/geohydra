require File.join(File.dirname(__FILE__), 'lib/geohydra/version')

Gem::Specification.new do |s|
  s.name = 'geohydra'
  s.version = GeoHydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '~> 1.9.3'
  s.authors = ['Darren Hardy']
  s.email = ['drh@stanford.edu']
  s.summary = %q{GeoHydra}
  s.description = %q{Geospatial MetaData ToolKit for use in a GeoHydra head}
  s.has_rdoc = true
  s.licenses = ['ALv2', 'Stanford University Libraries']
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'confstruct'
  s.add_dependency 'json'
  s.add_dependency 'fastimage'  
  s.add_dependency 'nokogiri', '~> 1.5.0'
  s.add_dependency 'rest-client'
  s.add_dependency 'rsolr'
  s.add_dependency 'rgeo'
  s.add_dependency 'rgeo-shapefile'
  s.add_dependency 'activerecord', '~> 3.2.0'
  s.add_dependency 'activesupport', '~> 3.2.0'
  s.add_dependency 'activerecord-postgresql-adapter'
  
  # SUL-DLSS gems
  s.add_dependency 'assembly-objectfile'
  s.add_dependency 'dor-services', '~> 4.2.20'
  s.add_dependency 'druid-tools', '~> 0.2.5'
  s.add_dependency 'mods'
  s.add_dependency 'rgeoserver', '~> 0.6.0'

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'equivalent-xml'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'redcarpet' # provides Markdown
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'version_bumper', '~> 0.4.0'
  s.add_development_dependency 'yard'
end
