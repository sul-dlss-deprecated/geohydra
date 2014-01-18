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
  s.licenses = ['ALv2', 'Stanford University']
  s.homepage = 'https://github.com/sul-dlss/geohydra'
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activerecord', '~> 3.2.0'
  s.add_dependency 'activerecord-postgresql-adapter', '~> 0.0.1'
  s.add_dependency 'activesupport', '~> 3.2.0'
  s.add_dependency 'assembly-objectfile', '~> 1.6.2'
  s.add_dependency 'awesome_print', '~> 1.2.0'
  s.add_dependency 'confstruct', '~> 0.2.5'
  s.add_dependency 'fastimage', '~> 1.5.4'
  s.add_dependency 'json', '~> 1.8.1'
  s.add_dependency 'nokogiri', '~> 1.6.0'
  s.add_dependency 'rest-client', '~> 1.6.7'
  s.add_dependency 'rgeo', '~> 0.3.20'
  s.add_dependency 'rgeo-shapefile', '~> 0.2.3'
  s.add_dependency 'rsolr', '~> 1.0.9'
  
  # SUL-DLSS gems on github
  s.add_dependency 'dor-services', '~> 4.4.14'
  s.add_dependency 'druid-tools', '~> 0.2'
  s.add_dependency 'mods', '~> 0.0.22'
  s.add_dependency 'rgeoserver', '~> 0.7.0'

  s.add_development_dependency 'equivalent-xml'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'redcarpet' # provides Markdown
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'version_bumper'
  s.add_development_dependency 'yard'
end
