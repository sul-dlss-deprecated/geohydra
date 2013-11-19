#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'json'

@@g = GeoHydra::Gazetteer.new

#
# Resolves placenames using local gazetteer
#
#   * Changes subject/geographic with GeoNames as authority to have the correct valueURI
#   * Adds correct rdf:resource to geo extension
#
def resolve_placenames(modsFn, flags)
  puts "Processing #{modsFn}" if flags[:verbose]
  mods = Nokogiri::XML(File.open(modsFn, 'rb'))
  r = mods.xpath('//mods:geographic[@authority=\'GeoNames\']', { 'mods' => 'http://www.loc.gov/mods/v3' })
  r.each do |i|
    ap({:i => i}) if flags[:debug]
    k = i.content # Gazetteer keyword
    uri = @@g.find_uri_by_keyword(k)
    if uri.nil?
      puts "WARNING: Missing gazetteer entry for '#{k}'" if flags[:verbose]
      next
    else
      i['valueURI'] = uri
      coverages = mods.xpath('//mods:extension//dc:coverage', { 'mods' => 'http://www.loc.gov/mods/v3', 'dc' => 'http://purl.org/dc/elements/1.1/' })
      coverages.each do |j|
        if j['dc:title'] == k
          puts "Correcting dc:coverage@rdf:resource for #{k}" if flags[:debug]
          j['rdf:resource'] = uri
        end
      end
    end
    
    lcnaf = @@g.find_lcnaf_by_keyword(k)
    ap({:lcnaf => lcnaf}) if flags[:debug]
    if not (lcnaf.nil? or k == lcnaf)
      puts "Adding Library of Congress NAF entry to end of MODS record" if flags[:verbose]
      mods.root << Nokogiri::XML("<subject><geographic authorityURI='http://id.loc.gov/authorities/names'>#{lcnaf}</geographic></subject>").root
    end
    ap({:i => i}) if flags[:debug]
  end
  
  mods.write_to(File.open(modsFn, 'wb'), :encoding => 'UTF-8', :indent => 2)
end

def main(flags)
  File.umask(002)
  puts "Searching for MODS records..." if flags[:verbose]
  puts flags[:workspacedir] + '/**/' + DruidTools::Druid.glob + '/metadata/descMetadata.xml' if flags[:debug]
  Dir.glob(flags[:workspacedir] + '/**/' + DruidTools::Druid.glob + '/metadata/descMetadata.xml') do |modsFn|
    ap({:modsFn => modsFn}) if flags[:debug]
    resolve_placenames(modsFn, flags)
  end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options]
EOM
    opts.on('-v', '--verbose', 'Run verbosely') do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on('--workspace DIR', "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
      flags[:workspacedir] = v
    end
  end.parse!

  %w{tmpdir stagedir workspacedir}.each do |k|
    d = flags[k.to_sym]
    raise ArgumentError, "Missing directory #{d}" unless d.nil? or File.directory? d
  end

  ap({:flags => flags}) if flags[:debug]
  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
