#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'json'

#
# Resolves placenames using local gazetteer
#
#   * Changes subject/geographic with GeoNames as authority to have the correct valueURI
#   * Adds correct rdf:resource to geo extension
#   * Adds a LCSH or LCNAF keyword if needed
#
def resolve_placenames(g, modsFn, flags)
  puts "Processing #{modsFn}" if flags[:verbose]
  mods = Nokogiri::XML(File.open(modsFn, 'rb'))
  r = mods.xpath('//mods:geographic', { 'mods' => 'http://www.loc.gov/mods/v3' })
  r.each do |i|
    ap({:i => i}) if flags[:debug]
    k = i.content 
    
    # Verify Gazetteer keyword
    uri = g.find_uri_by_keyword(k)
    if uri.nil?
      puts "WARNING: Missing gazetteer entry for '#{k}'" if flags[:verbose]
      next
    end

    # Ensure correct valueURI for subject/geographic for GeoNames
    i['valueURI'] = uri
    i['authority'] = 'geonames'
    i['authorityURI'] = 'http://www.geonames.org/ontology#'

    # Correct any linkages for placenames in the geo extension
    coverages = mods.xpath('//mods:extension//dc:coverage', { 'mods' => 'http://www.loc.gov/mods/v3', 'dc' => 'http://purl.org/dc/elements/1.1/' })
    coverages.each do |j|
      if j['dc:title'] == k
        puts "Correcting dc:coverage@rdf:resource for #{k}" if flags[:debug]
        j['rdf:resource'] = uri + '/about.rdf'
      end
    end
    
    # Add a LC heading if needed
    lc = g.find_lc_by_keyword(k)
    ap({:lc => lc}) if flags[:debug]
    unless lc.nil? or k == lc
      puts "Adding Library of Congress entry to end of MODS record" if flags[:verbose]
      lcauth = g.find_lcauth_by_keyword(k)
      unless lcauth.nil?
        lcuri = g.find_lcuri_by_keyword(k)
        unless lcuri.nil?
          lcuri = " valueURI='#{lcuri}'"
        end
        i.parent.parent << Nokogiri::XML("
<subject>
  <geographic authority='#{lcauth}'#{lcuri}>#{lc}</geographic>
</subject>
").root
      end
    end
    ap({:i => i}) if flags[:debug]
  end
  
  # Save XML tree
  mods.write_to(File.open(modsFn, 'wb'), :encoding => 'UTF-8', :indent => 2)
end

def main(flags)
  g = GeoHydra::Gazetteer.new
  File.umask(002)
  puts "Searching for MODS records..." if flags[:verbose]
  Dir.glob(flags[:workspacedir] + '/**/' + DruidTools::Druid.glob + '/metadata/descMetadata.xml') do |modsFn|
    resolve_placenames(g, modsFn, flags)
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

  %w{workspacedir}.each do |k|
    d = flags[k.to_sym]
    raise ArgumentError, "Missing directory #{d}" unless d.nil? or File.directory? d
  end

  ap({:flags => flags}) if flags[:debug]
  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
