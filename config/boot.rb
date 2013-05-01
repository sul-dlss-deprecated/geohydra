require 'rubygems'
require 'bundler/setup'
require 'logger'

environment  = ENV['ROBOT_ENVIRONMENT'] ||= 'development'
GEOMDTK_ROOT = File.expand_path(File.dirname(__FILE__) + '/..')

require 'dor-services'

# require 'lyber_core'
ENV_FILE = GEOMDTK_ROOT + "/config/environments/#{environment}.rb"
require ENV_FILE

# Project dir in load path.
$LOAD_PATH.unshift(GEOMDTK_ROOT + '/lib')

# Development dependencies.
if ['local', 'development'].include? environment
  # require 'awesome_print'
  require 'pp'
end

# Load the project and its dependencies.
require 'geomdtk'
