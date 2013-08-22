require 'druid-tools'

module GeoMDTK
  class Utils
    def self.find_druid_folders(dir = '.')
      Dir.glob(File.join(dir, '**', DruidTools::Druid.glob + '/')).sort.collect do |p|
        yield p if block_given?
        p
      end
    end
    
    # @see http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf pg2
    def self.shapefile?(fn)
      File.basename(fn).downcase =~ /^([a-z0-9_-]+)\.shp$/
      $1.present?
    end
  end
end