require 'rubygems'
require 'bundler/setup'

ENV['GEOMDTK_ENVIRONMENT'] ||= 'development'
GEOMDTK_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'confstruct'
ENV_FILE = GEOMDTK_ROOT + "/config/environments/#{ENV['GEOMDTK_ENVIRONMENT']}"
require ENV_FILE

# Development dependencies.
if ['local', 'development'].include? ENV['GEOMDTK_ENVIRONMENT']
  require 'awesome_print'
end

# Load the project and its dependencies.
require 'geomdtk'
