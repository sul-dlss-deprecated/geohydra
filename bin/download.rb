#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'

tmpdir = 'tmp'

client = GeoMDTK::GeoNetwork.new
client.each do |uuid|
  obj = client.fetch(uuid)
  if obj.druid
    druid = DruidTools::Druid.new(obj.druid, '/tmp/dor_workspace')
    raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
    druid.mkdir unless File.directory? druid.path


    client.export(uuid, tmpdir)
    system("unzip -jo -qq #{tmpdir}/#{uuid}.mef #{uuid}/metadata/*.xml -d #{tmpdir}")
    %w{metadata.iso19139.xml metadata.xml}.each do |fn|
      fn = File.join(tmpdir, fn)
      if File.exist? fn
        xfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
        ap "Copying #{fn} => #{xfn}"
        File.rename(fn, xfn)
        
        yfn = File.join(druid.metadata_dir, 'descMetadata.xml')
        xslt = File.dirname(__FILE__) + '/../lib/geomdtk/iso2mods.xsl'
        ap "Transforming #{xfn} => #{yfn}"
        system("xsltproc --output '#{yfn}' '#{xslt}' '#{xfn}'")
        break
      end
    end
  else
      $stderr.puts "uuid #{uuid} missing druid"
  end
end