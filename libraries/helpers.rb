#
# Cookbook Name:: postgresql
# Library:: helpers
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) 2012-2014 LLC Express 42
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Postgreql modules
module Postgresql
  # Helpers module
  module Helpers
    def exec_in_pg_cluster(cluster_version, cluster_name, sql)
      return false unless pg_running?(cluster_version, cluster_name)
      postmaster_content = ::File.open("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/postmaster.pid").readlines
      pg_port = postmaster_content[3].to_i
      psql_status = Mixlib::ShellOut.new("su -c 'psql -p #{pg_port} -q -t -c \"#{sql};\"' postgres")
      psql_status.run_command
      psql_status.stdout
    end

    def need_to_restart(cluster_version, cluster_name, advanced_options, node)
      if advanced_options[:restart_if_first_run]
        if defined?(node['postgresql'][cluster_version][cluster_name]['success_at_least_once'])
          false
        else
          true
        end
      end
    end

    def pg_running?(cluster_version, cluster_name)
      pg_status = Mixlib::ShellOut.new("su -c '/usr/lib/postgresql/#{cluster_version}/bin/pg_ctl \
        -D /var/lib/postgresql/#{cluster_version}/#{cluster_name} status' postgres")
      pg_status.run_command
      if pg_status.stdout =~ /server\ is\ running/
        return true
      else
        return false
      end
    end
  end
end
