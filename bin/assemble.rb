#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'

TMPDIR = Dor::Config.geomdtk.tmpdir || 'tmp'
WORKDIR = Dor::Config.geomdtk.workspace || 'workspace'
STAGEDIR = Dor::Config.geomdtk.stage || 'stage'

def do_system cmd
  puts cmd
  system(cmd)
end

def main(workdir = WORKDIR, tmpdir = TMPDIR, stagedir = STAGEDIR)
  client = GeoMDTK::GeoNetwork.new
  client.each do |uuid|
    puts "Processing #{uuid}"
    obj = client.fetch(uuid)
    unless obj.druid
      # raise ArgumentError, "uuid #{uuid} missing druid" 
      next
    end
    
    # setup
    druid = DruidTools::Druid.new(obj.druid, workdir)
    raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
    [druid.path, druid.content_dir, druid.metadata_dir].each do |d|
      FileUtils.mkdir_p d unless File.directory? d
    end

    # export MEF
    client.export(uuid, tmpdir)
    do_system("umask 002; unzip -jo -qq #{tmpdir}/#{uuid}.mef #{uuid}/metadata/*.xml -d #{tmpdir}")
    %w{metadata.iso19139.xml metadata.xml}.each do |fn|
      fn = File.join(tmpdir, fn)
      if File.exist? fn
        xfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
        puts "Copying #{fn} => #{xfn}"
        File.rename(fn, xfn)

        yfn = File.join(druid.metadata_dir, 'descMetadata.xml')
        xslt = File.dirname(__FILE__) + '/../lib/geomdtk/iso2mods.xsl'
        puts "Transforming #{xfn} => #{yfn}"
        do_system("xsltproc --output '#{yfn}' '#{xslt}' '#{xfn}'")
        break
      end
    end
    
    # export content
    Dir.glob(File.join(stagedir, "#{druid.id}.zip")) do |fn|
      do_system("umask 002; unzip -nj -qq #{fn} -d #{druid.content_dir}")
    end    
  end
end

main