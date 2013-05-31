require 'rubygems'
require 'rspec/core/rake_task'
require 'bundler'
require 'yard'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

task :spec do
  RSpec::Core::RakeTask.new
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   # optional
  t.options = ['--any', '--extra', '--opts'] # optional
end

task :default do
  $stderr.puts "Targets are spec and clean"
end

# # To release the gem to the DLSS gemserver, run 'rake dlss_release'
# require 'dlss/rake/dlss_release'
# Dlss::Release.new

