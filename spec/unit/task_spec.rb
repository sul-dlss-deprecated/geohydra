# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')
require 'rspec'

DRUIDS = %w{aa111bb2222 cc333dd4444 ee555ff6666 gg777hh8888 ii999jj0000}
DRUID = DRUIDS[0]

INVALID_DRUIDS = %w{NotADruid!!! AA111bb2222 aa11bb22222}
INVALID_DRUID = INVALID_DRUIDS[0]

describe GeoHydra::Task do
  before(:each) do
    @t = GeoHydra::Task.new :druid => DRUID
    # ap({:t => @t})
  end
  
  describe '#init' do
    it 'valid' do
      @t.class.should == GeoHydra::Task
      t = GeoHydra::Task.new :notanarg => 'nonsense'
      t.class.should == GeoHydra::Task
    end
    
    it 'invalid' do
      expect { GeoHydra::Task.new :druid => INVALID_DRUID }.to raise_error ArgumentError
    end
  end

  describe '#perform' do
    it 'invalid' do
      expect { @t.perform }.to raise_error NotImplementedError
    end
  end
  
  describe '#valid_status?' do
    it 'valid' do
      @t.valid_status?('HOLD').should == true
      @t.valid_status?('hold').should == true
      @t.valid_status?('HolD').should == true
      @t.valid_status?('READY').should == true
      @t.valid_status?('RUNNING').should == true
      @t.valid_status?('DEFERRED').should == true
      @t.valid_status?('ERROR').should == true
      @t.valid_status?('COMPLETED').should == true
    end
    
    it 'invalid' do
      @t.valid_status?('foobar').should == false
    end
  end
  
  describe '#druid=' do
    it 'valid' do
      DRUIDS.each do |druid|
        t = GeoHydra::Task.new :druid => druid
        t.druid.id.should == druid
        t.druid.druid.should == "druid:#{druid}"
      end
    end

    it 'invalid' do
      INVALID_DRUIDS.each do |druid|
        expect { GeoHydra::Task.new :druid =>druid }.to raise_error ArgumentError
      end
    end
  end
end
