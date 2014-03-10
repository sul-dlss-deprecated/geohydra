#!/usr/bin/env ruby
#
# run_task.rb - Run a single workflow task with the given druid
#
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

# __MAIN__
begin
  (wf, task, druid) = ARGV
  wf = wf[0].capitalize + wf[1..-1]
  task = task.split(/-/).map(&:capitalize).join('')
  ap({:wf => wf, :task => task, :druid => druid}) if $DEBUG
  klassWF = eval('GeoHydra::' + wf + '::' + task + 'Task')
  puts klassWF.new.perform({:druid => druid})
rescue Exception => e
  puts "ERROR: #{e.class}: #{e}"
  puts <<-EOM
Usage: run_task workflowWF task druid
  
       bin/geohydra run_task gisAssemblyWF generate-mods aa111bb2222
EOM
end

