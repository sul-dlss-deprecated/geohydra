require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geomdtk'
require 'nokogiri'

describe do
  before(:all) do
    @xml = {}
    Dir.glob('**/fixtures/*_descMetadata.xml') do |fn|
      # ap({:fn => fn})
      @xml[fn] = Nokogiri::XML(File.read(fn))
    end
  end
  
  describe "#to_ogp_solr" do
    it "#convert" do
      @xml.each do |fn, descMetadata|
        druid = $1 if fn =~ %r{/([a-z0-9]{11})_descMetadata.xml$}
        # ap({:druid => druid})
        purl = "http://purl.stanford.edu/#{druid}"
        cmd = ['xsltproc',
                "--stringparam geometryType 'Point'",
                "--stringparam geoserver_root 'http://host/geoserver'",
                "--stringparam stacks_root 'http://host/stacks'",
                "--stringparam purl '#{purl}'",
                # "--output #{fn.gsub('descMetadata', 'ogpSolr')}",
                "'#{File.expand_path(File.dirname(__FILE__) + '/../lib/geomdtk/mods2ogp.xsl')}'",
                "#{fn}",
                "| diff --ignore-all-space - #{fn.gsub('descMetadata', 'ogpSolr')}"
                ].join(' ')
        # ap({:cmd => cmd})
        puts "Testing #{fn}..."
        r = system(cmd)
        # ap({:r => r})
        r.should == true
      end
    end
  end
  
end
