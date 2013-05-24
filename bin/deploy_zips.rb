require 'druid-tools'
require 'fileutils' # Druid.mkdir requires this on vanilla 1.8.7 ruby

Dir.glob("../staging/druid/*.zip").each do |fn|
  druid = DruidTools::Druid.new("druid:" + File.basename(fn, '.zip'))
  puts druid
  druid.mkdir unless File.directory?(druid.path)
  cmd = "unzip -o #{fn} -d #{druid.path}"
  puts cmd
  system(cmd)
end
