#!/usr/bin/env ruby
#
# Sensu IRC Handler
# ===
#
# This handler reports alerts to a specified IRC channel. You need to
# set the options in the irc.json configuration file, located by default
# in /etc/sensu. Set the irc_server option to control the IRC server to
# connect to, the irc_password option to set an optional channel
# password and the irc_ssl option to true to enable an SSL connection if
# required. An example file is contained in this irc handler directory.
#
# Copyright 2011 James Turnbull
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

$: << '/etc/sensu/handlers'

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'pantheon_handler'
require 'carrier-pigeon'
require 'timeout'

class PantheonIRC < Sensu::PantheonHandler
  # Set class for Sensu::Handler's auto running
  @@autorun = self

  # This is used to merge in configs
  def handler_name
    'irc'
  end

  def pantheon_handle
    params = {
      :uri => merged_settings["irc_server"],
      :message => "#{short_name}: #{@event['check']['output']}",
      :ssl => merged_settings["irc_ssl"],
      :join => true,
    }

    # Check if the output is json.  If so, see if we can
    # construct and smarter messages, including URL
    begin
      parsed_output = ::JSON.parse(@event['check']['output'])
      if parsed_output["message"] && parsed_output["url"]
        params[:message] = "#{parsed_output["message"]}: #{parsed_output["url"]}"
      elsif parsed_output["message"]
        params[:message] = parsed_output["message"]
      end
    rescue Exception => e
      # Message ain't JSON
      params[:message] = @event['check']['output']
    end

    if settings["handlers"]["irc"].has_key?("irc_password")
      params[:channel_password] = settings["handlers"]["irc"]["irc_password"]
    end

    begin
      timeout(10) do
        CarrierPigeon.send(params)
        puts 'irc -- sent alert for ' + short_name + ' to IRC.'
      end
    rescue Timeout::Error
      puts 'irc -- timed out while attempting to ' + @event['action'] + ' a incident -- ' + short_name
    end
  end

end
