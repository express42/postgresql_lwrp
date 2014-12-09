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

class Chef
  # Postgresql modules
  module Postgresql
    # Helpers module
    module Helpers
      def pg_installed?(pkg_name)
        dpkg_status = Mixlib::ShellOut.new("dpkg-query -W -f='${Status}\n' #{pkg_name} 2>/dev/null | grep -c -q 'ok installed'")
        dpkg_status.run_command
        if dpkg_status.exitstatus == 0
          false
        else
          true
        end
      end

      def exec_in_pg_cluster(cluster_version, cluster_name, sql)
        return [nil, nil] unless pg_running?(cluster_version, cluster_name)
        pg_port = get_pg_port(cluster_version, cluster_name)
        psql_status = Mixlib::ShellOut.new("echo -n \"#{sql};\" | su -c 'psql -t -p #{pg_port}' postgres")
        psql_status.run_command
        [psql_status.stdout, psql_status.stderr]
      end

      def get_pg_port(cluster_version, cluster_name)
        return [nil, nil] unless pg_running?(cluster_version, cluster_name)
        postmaster_content = ::File.open("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/postmaster.pid").readlines
        postmaster_content[3].to_i
      end

      def need_to_restart?(allow_restart_cluster, first_time)
        if allow_restart_cluster == :first
          return first_time
        elsif allow_restart_cluster == :always
          return true
        end
        false
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

      def create_user(cluster_version, cluster_name, cluster_user, options)
        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, 'SELECT usename FROM pg_user')
        fail "postgresql create_user: can't get users list" unless stderr.empty?

        if stdout.include? cluster_user
          log("postgresql create_user: user '#{cluster_user}' already exists, skiping")
          return nil

        else
          stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, "CREATE USER \\\"#{cluster_user}\\\" #{options.map { |t| t.join(' ') }.join(' ')}")
          fail "postgresql create_user: can't create user #{cluster_user}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stdout.include?("CREATE ROLE\n")
          log("postgresql create_user: user '#{cluster_user}' created")
        end
      end

      def create_database(cluster_version, cluster_name, cluster_database, options)
        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, 'SELECT datname FROM pg_database')
        fail "postgresql create_database: can't get database list" unless stderr.empty?

        if stdout.include? cluster_database
          log("postgresql create_database: database '#{cluster_database}' already exists, skiping")
          return nil

        else
          stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, "CREATE DATABASE \\\"#{cluster_database}\\\" #{options.map { |t| t.join(' ') }.join(' ')}")
          fail "postgresql create_database: can't create database #{cluster_database}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stdout.include?("CREATE DATABASE\n")
          log("postgresql create_database: database '#{cluster_database}' created")
        end
      end

      def configuration_hacks(configuration, cluster_version)
        configuration.delete('ssl_cert_file') if cluster_version.to_f < 9.2
        configuration.delete('ssl_key_file') if cluster_version.to_f < 9.2
        configuration.delete('wal_receiver_status_interval') if cluster_version.to_f < 9.1
        configuration.delete('hot_standby_feedback') if cluster_version.to_f < 9.1
      end
    end
  end
end
