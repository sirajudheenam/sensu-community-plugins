#!/usr/bin/env ruby
#
# Check Vmware Datastore Plugin
# ===

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
    pod = vim.serviceInstance.content.rootFolder.childEntity.first.datastoreFolder.childEntity.select{|s| s.is_a?(RbVmomi::VIM::StoragePod) }.first.summary
    name = pod.name
    capacity = pod.capacity
    freeSpace = pod.freeSpace
    utilisation = 100 - ( freeSpace * 100 / capacity )
    crit "CRITICAL #{name} - #{utilisation}%" if utilisation >= config[:crit]
    warn "WARNING #{name} - #{utilisation}%" if utilisation >= config[:warn]
    ok "OK #{name} - #{utilisation}%"
  end
end
