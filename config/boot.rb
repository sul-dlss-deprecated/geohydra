require 'rubygems'
require 'bundler/setup'

ENV['GEOHYDRA_ENVIRONMENT'] ||= 'development'
GEOHYDRA_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'confstruct'
ENV_FILE = GEOHYDRA_ROOT + "/config/environments/#{ENV['GEOHYDRA_ENVIRONMENT']}"
require ENV_FILE

# Development dependencies.
if ['local', 'development'].include? ENV['GEOHYDRA_ENVIRONMENT']
  require 'awesome_print'
end

# Load the project and its dependencies.
require 'geohydra'
