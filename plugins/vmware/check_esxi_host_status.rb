#!/usr/bin/env ruby
#
# Check Vmware Host Connection Status Plugin
# ===

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'rbvmomi'

class CheckVmwareHostStatus < Sensu::Plugin::Check::CLI

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
      warn_status = ""
      err_status = ""
    sc = vim.serviceInstance.content
    rootFolder = sc.rootFolder
    dc_array= rootFolder.children.find_all
        dc_array.each do |child|
                compute_cluster = child.hostFolder.children
                compute_cluster.each do |clus|
                        host_array=clus.host
                        host_array.each do |h|
                                        if h.summary.runtime.powerState =="poweredOff"
                                            warn_status+="#{h.summary.config.name.upcase}: is Powered Off; "
                                        elsif h.summary.runtime.powerState == "standBy"
                                            warn_status+="#{h.summary.config.name.upcase}: is running as Stand By node; "
                                        elsif h.summary.runtime.powerState == "unknown"
                                            err_status+="#{h.summary.config.name.upcase}: is in UNKNOWN power state - Check host & reconnect, if required; "
                                        end
                                        if h.summary.runtime.connectionState =="Disconnected"
                                            err_status+="#{h.summary.config.name.upcase}: is disconnected; "
                                        elsif h.summary.runtime.connectionState == "NotResponding"
                                            err_status+="#{h.summary.config.name.upcase}: is not responding; "
                                        elsif h.summary.runtime.inMaintenanceMode
                                            warn_status+="#{h.summary.config.name.upcase}: is in maintenance mode; "
                                        end
                        end
                end
        end
      critical "#{config[:host]} #{err_status} #{warn_status}" if ! err_status.empty?
      warning "#{config[:host]} #{warn_status} #{err_status}" if ! warn_status.empty?
      ok "#{config[:host]} Power & Connection status is OK" if warn_status.empty? && err_status.empty?
  end
end
