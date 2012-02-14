#!/usr/bin/env ruby
#
# Check Graphite
# ===
#
# Checks a graphite series, checking the average of the datapoints.
# ./check-graphite.rb -u 'http://graphite/render/?target=this.that&from=-40minutes&format=json' --critical 1300 --warning 1200 -n 'Some metric'
#

$: << '/etc/sensu/plugins'

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'
require 'net/http'
require 'net/https'

require 'pantheon-check-http'

class PantheonCheckHTTP < Sensu::Plugin::PantheonCheck

  option :warning, :long => '--warning VALUE', :proc => proc {|a| a.to_i }, :required => true
  option :critical, :long => '--critical VALUE', :proc => proc {|a| a.to_i }, :required => true
  option :debug, :long => '--debug', :boolean => true, :default => false
  option :name, :long => '--name NAME', :short => '-n NAME', :required => true

  def handle_response(res)
    case res.code
    when /^2/
      result = JSON::load(res.body)
      puts "Result:\n#{result.inspect}" if config[:debug]
      datapoints = result.first["datapoints"].map{|x,y| x.to_i}.flatten.reject{|x| x.zero?}
      puts "Data Points:\n#{datapoints.inspect}" if config[:debug]
      avg = datapoints.inject{ |sum, el| sum + el }.to_f / datapoints.size
      puts "Average Value:\n#{avg}" if config[:debug]
      if avg > config[:critical]
        critical :message => "#{config[:name]} is #{avg} (threshold: #{config[:critical]})",
                 :url => construct_url
      elsif avg > config[:warning]
        warning :message => "#{config[:name]} is #{avg} (threshold: #{config[:warning]})",
                :url => construct_url
      else
        ok :message => "#{config[:name]} is #{avg}",
           :url => construct_url
      end
    when /^4/, /^5/
      critical res.code
    else
      warning res.code
    end
  end

end
