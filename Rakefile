require 'rubygems'
require 'rake'
require 'bundler'

# Dir.glob('lib/tasks/*.rake').each { |r| import r }

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
#  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb', 'test/**/*.rb'
end

RSpec::Core::RakeTask.new(:functional) do |spec|
#  spec.libs << 'lib' << 'spec' << 'test'
  spec.pattern = 'spec/**/*_spec.rb', 'test/**/*.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

RSpec::Core::RakeTask.new(:unit) do |spec|
#  spec.libs << 'lib' << 'spec'  
  spec.pattern = 'test/**/*.rb'
  spec.rcov = true
end

task :rcov => ["functional"] do
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

task :default => [:spec]

# # To release the gem to the DLSS gemserver, run 'rake dlss_release'
# require 'dlss/rake/dlss_release'
# Dlss::Release.new

