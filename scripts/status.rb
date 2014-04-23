#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'awesome_print'

JSON::parse(File.read('status.json')).each do |h|
  # ap({:h => h})
  uri = URI(h['submitted_query'])
  druid = 'unknown'
  druid = $1 if uri.to_s =~ /druid%3A([a-z0-9]+)/
  # ap({:uri => uri})
  uri.host = 'localhost'
  uri.port = 8080
  # ap({:uri => uri})
  begin
    start = Time.now
    res = Net::HTTP.get_response(uri)
    sz = res.body.size
    puts [Time.now, druid, res.code, res['content-type'], sz, res['geowebcache-cache-result'], Time.now - start].join(', ')
  rescue => e
    puts e.class, e
  end
  sleep(0.5)
end