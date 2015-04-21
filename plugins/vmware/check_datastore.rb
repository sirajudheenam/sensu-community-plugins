#!/usr/bin/env ruby
#
# It checks the utilisation of Datastore cluster and individual datastores attached to the VCENTER
# ===
# Usage :   /opt/sensu/embedded/bin/ruby check-vmware-datastore-shared.rb -H IP_OR_FQDN_OF_VCENTER -u USERNAME -p PASSWORD

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'rbvmomi'

class CheckVmwareDatastore < Sensu::Plugin::Check::CLI

  option :host,
         :short => '-H HOST',
         :proc => proc {|a| a.to_s },
         :required => true

  option :user,
         :short => '-u USER',
         :proc => proc {|a| a.to_s },
         :required => true

  option :pass,
         :short => '-p PASS',
         :proc => proc {|a| a.to_s },
         :required => true

  option :warn,
         :short => '-w PERCENT',
         :proc => proc {|a| a.to_i },
         :default => 80

  option :crit,
         :short => '-c PERCENT',
         :proc => proc {|a| a.to_i },
         :default => 90

  def initialize
    super
  end

  def run
    vim = RbVmomi::VIM.connect :host => config[:host], :user => config[:user], :password => config[:pass], :insecure => true
      rootFolder = vim.serviceInstance.content.rootFolder
      sc = vim.serviceInstance.content
      warn_status, err_status="", ""
      siRoot = sc.rootFolder.children.find_all
      siRoot.each do |child|
          dataS = child.datastoreFolder.childEntity
          dataS.each do |ds|
              name = ds.name
              capacity = ds.summary.capacity
              freeSpace = ds.summary.freeSpace
              utilisation = 100 - ( freeSpace * 100 / capacity )
              if ds.class == RbVmomi::VIM::StoragePod  then
                 warn_status+="#{name}|USED:#{utilisation}%; " if utilisation >= config[:warn] && utilisation < config[:crit]
                 err_status+="#{name}|USED:#{utilisation}%; " if utilisation >= config[:crit]
               else
                 warn_status+="#{name}|USED:#{utilisation}%; " if utilisation >= config[:warn] && utilisation < config[:crit]
                 err_status+="#{name}|USED:#{utilisation}%; " if utilisation >= config[:crit]
              end
          end
      end
    vim.close
    critical "#{err_status}&#{warn_status}" if (!err_status.empty? && !warn_status.empty?)
    critical "#{err_status}" if (!err_status.empty? && warn_status.empty?)
    warning "#{warn_status}" if (err_status.empty? && ! warn_status.empty?)
    ok "All Datastores are under threshold" if (err_status.empty? && warn_status.empty?)
  end
end
