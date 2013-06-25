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

desc "Run console; defaults to IRB='pry'"
task :console, :IRB do |t, args|
  irb = args[:IRB].nil?? 'pry' : args[:IRB]
  sh irb, "-r", "#{File.dirname(__FILE__)}/config/boot.rb"
end

desc "Run tests"
task :spec do
  RSpec::Core::RakeTask.new
end

desc "Build documentation"
task :yard do
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', 'bin/**/*.rb']
  end
end

desc "Runs 'rake spec yard'"
task :default => [:spec, :yard]