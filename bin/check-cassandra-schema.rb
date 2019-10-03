#! /usr/bin/env ruby
#
# check-cassandra-schema
#
# DESCRIPTION:
#   This plugin uses Apache Cassandra's `nodetool` to check to see
#   if any node in the cluster has run into a schema disagreement problem
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: english
#   Cassandra's nodetool
#
# USAGE:
#   #YELLOW
#
# NOTES:
#   See http://www.datastax.com/documentation/cassandra/2.0/cassandra/dml/dml_handle_schema_disagree_t.html
#   for more details
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'English'

#
# Check Cassandra Schema
#
class CheckCassandraSchema < Sensu::Plugin::Check::CLI
  option :hostname,
         short: '-h HOSTNAME',
         long: '--host HOSTNAME',
         description: 'cassandra hostname',
         default: 'localhost'

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'cassandra JMX port',
         default: '7199'

  option :user,
         short: '-u USER',
         long: '--user USER',
         description: 'cassandra JMX username',
         default: 'cassandra'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'cassandra JMX password',
         default: 'cassandra'

  # execute cassandra's nodetool and return output as string
  def nodetool_cmd(cmd)
    out = `nodetool -h #{config[:hostname]} -p #{config[:port]} -u #{config[:user]} -pw #{config[:password]} #{cmd} 2>&1`
    [out, $CHILD_STATUS]
  end

  def run
    out, rc = nodetool_cmd('describecluster')
    if rc != 0
      critical(out)
    end

    bad_nodes = []
    # #YELLOW
    out.each_line do |line|
      if m = line.match(/\s+UNREACHABLE:\s+(.*)\[(.*)\]\s+$/)# rubocop:disable all
        bad_nodes << m[2]
        next
      end
      if bad_nodes.count > 0
        if m = line.match(/\s+(.*)\[(.*)\]\s+$/)# rubocop:disable all
          bad_nodes << m[2]
        end
      end
    end

    if bad_nodes.count > 0
      critical('nodes ' + bad_nodes.join(', ') + ' are in schema disagreement')
    else
      ok
    end
  end
end
