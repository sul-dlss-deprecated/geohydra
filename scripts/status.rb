#!/usr/bin/env ruby

require 'csv'
# require 'json'
require 'net/http'
# require 'awesome_print'

STDOUT.sync = true

CSV.foreach('status.csv') do |url|
  # ap({:url => url.first})
  uri = URI(url.first)
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
    open("images/#{druid}.png", 'wb') do |f|
      f.write(res.body)
    end
    finish = Time.now
    puts [finish, druid, res.code, res['content-type'], sz, res['geowebcache-cache-result'], finish - start].join(', ')
  rescue => e
    puts e.class, e
  end
  sleep(0.5)
end