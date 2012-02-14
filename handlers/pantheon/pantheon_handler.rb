require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'net/http'
require 'json'
require 'sensu-handler'

module Sensu
  class PantheonHandler < Sensu::Handler

    # Special Ruby Stuff:
    #  * merged_settings: Lots more specificity avaiable
    # Special Config Stuff
    #  * handle_warns: see whether to alert on warns
    #  * max_occurrences: only alert after max_occurrences occurrences

    # {
    #   "handlers": {
    #     "irc": {
    #       "type": "pipe",
    #       "command": "/etc/sensu/handlers/pantheon_irc.rb",
    #       "irc_server": "irc://myops@irc.freenode.net:6667/#my-ops",
    #       "irc_ssl": false
    #     }
    #   },
    #   "checks": {
    #     "some_check": {
    #       "handler": "irc",
    #       "command": "/etc/sensu/plugins/check-port.rb -p 8443",
    #       "interval": 60,
    #       "subscribers": [ "yggdrasil" ]
    #     },
    #     "another_check": {
    #       "handler": "irc",
    #       "command": "/etc/sensu/plugins/check-port.rb -p 8443",
    #       "interval": 60,
    #       "subscribers": [ "yggdrasil" ],
    #       "handle_warnings": false
    #     },
    #     "yet_another_check": {
    #       "handler": "irc",
    #       "command": "/etc/sensu/plugins/check-port.rb -p 8443",
    #       "interval": 60,
    #       "subscribers": [ "yggdrasil" ],
    #       "irc": {
    #         "irc_server": "irc://myops@irc.freenode.net:6667/#different-ops",
    #        }
    #     }
    #   }
    # }

    def short_name
      @event['client']['name'] + '/' + @event['check']['name']
    end

    def handler_name
      self.class.to_s.downcase
    end

    def check_name
      @event['check']['name']
    end

    def merged_settings
      # defaults
      configs = {
        'handle_warnings' => true,
        'max_occurrences' => 0
      }

      # Get configs from global configs
      configs.merge!(settings[handler_name] || {})

      # Get configs from per-handler configs
      configs.merge!(settings['handlers'][handler_name] || {})

      # Get per-check configs
      configs.merge!(settings['checks'][check_name] || {})

      # Get per-check, per-handler configs
      if settings['checks'][check_name]
        configs.merge!(settings['checks'][check_name][handler_name] || {})
      end
      configs
    end

    def handle
      if !merged_settings['handle_warnings'] && @event['check']['status'] == 1
        puts "Warning event, which '#{handler_name}' is configed to not handle."
        return
      end

      if @event['occurrences'].to_i <= merged_settings['max_occurrences']
        puts "#{@event['occurrences'].to_i} occurences is acceptable (theshold #{merged_settings['max_occurrences']})"
        return
      end

      pantheon_handle
    end

    def pantheon_handle    
      raise "Subclass this"
    end
  end
end
