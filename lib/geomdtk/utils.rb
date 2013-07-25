require 'druid-tools'

module GeoMDTK
  class Utils
    def self.find_druid_folders(dir = '.')
      Dir.glob(File.join(dir, '**', DruidTools::Druid.glob + '/')).collect do |p|
        yield p if block_given?
        p
      end
    end
  end
end