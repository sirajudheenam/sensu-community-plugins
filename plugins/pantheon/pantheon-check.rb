require 'sensu-plugin'
require 'sensu-plugin/check/cli'

module Sensu
  module Plugin
    class PantheonCheck < Check::CLI

      # Output json or a string:
      #   critical "Something's wrong!"
      #   warning({
      #     :message => "Something's not right!",
      #     :url => "http://ops.dashboard.mysite.com/queue"
      #   })
      def output(obj=nil)
        if obj.is_a?(String)
          puts obj
        elsif obj.is_a?(Hash)
          obj['timestamp'] ||= Time.now.to_i
          puts ::JSON.generate(obj)
        end
      end

    end
  end
end
