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
        return false if dpkg_status.exitstatus == 0
        true
      end

      def systemd_used?
        systemd_checker = Mixlib::ShellOut.new('file /sbin/init')
        systemd_checker.run_command
        return true if systemd_checker.stdout =~ /systemd/
        false
      end

      def exec_in_pg_cluster(cluster_version, cluster_name, *cluster_database, sql)
        return [nil, "PostgreSQL cluster #{cluster_name} not running!"] unless pg_running?(cluster_version, cluster_name)
        pg_port = get_pg_port(cluster_version, cluster_name)
        psql_status = Mixlib::ShellOut.new("echo -n \"#{sql};\" | su -c 'psql -t -p #{pg_port} #{cluster_database.first}' postgres")
        psql_status.run_command
        [psql_status.stdout, psql_status.stderr]
      end

      def get_pg_port(cluster_version, cluster_name)
        return [nil, nil] unless pg_running?(cluster_version, cluster_name)
        postmaster_content = ::File.open("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/postmaster.pid").readlines
        postmaster_content[3].to_i
      end

      def need_to_restart?(allow_restart_cluster, first_time)
        return first_time if allow_restart_cluster == :first
        return true if allow_restart_cluster == :always
        false
      end

      def pg_running?(cluster_version, cluster_name)
        pg_status = Mixlib::ShellOut.new("su -c '/usr/lib/postgresql/#{cluster_version}/bin/pg_ctl \
          -D /var/lib/postgresql/#{cluster_version}/#{cluster_name} status' postgres")
        pg_status.run_command
        return true if pg_status.stdout =~ /server\ is\ running/
        false
      end

      def create_user(cluster_version, cluster_name, cluster_user, options)
        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, 'SELECT usename FROM pg_user')
        raise "postgresql create_user: can't get users list\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stderr.empty?

        if stdout.include? cluster_user
          Chef::Log.info("postgresql create_user: user '#{cluster_user}' already exists, skiping")
          return nil

        else
          stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, "CREATE USER \\\"#{cluster_user}\\\" #{options.map { |t| t.join(' ') }.join(' ')}")
          raise "postgresql create_user: can't create user #{cluster_user}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stdout.include?("CREATE ROLE\n")
          Chef::Log.info("postgresql create_user: user '#{cluster_user}' created")
        end
      end

      def create_database(cluster_version, cluster_name, cluster_database, options)
        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, 'SELECT datname FROM pg_database')
        raise "postgresql create_database: can't get database list\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stderr.empty?

        if stdout.gsub(/\s+/, ' ').split(' ').include? cluster_database
          Chef::Log.info("postgresql create_database: database '#{cluster_database}' already exists, skiping")
          return nil

        else
          stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, "CREATE DATABASE \\\"#{cluster_database}\\\" #{options.map { |t| t.join(' ') }.join(' ')}")
          raise "postgresql create_database: can't create database #{cluster_database}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stdout.include?("CREATE DATABASE\n")
          Chef::Log.info("postgresql create_database: database '#{cluster_database}' created")
        end
      end

      def extension_available?(cluster_version, cluster_name, extension)
        stdout, _stderr = exec_in_pg_cluster(cluster_version, cluster_name, 'SELECT name FROM pg_available_extensions')
        return true if stdout.include? extension
        false
      end

      def install_extension(cluster_version, cluster_name, cluster_database, extension, options)
        raise "extension '#{extension}' is not available, please use \'pgxn_extension\' resource to install the extention" unless extension_available?(cluster_version, cluster_name, extension)

        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, cluster_database, 'SELECT extname FROM pg_extension')
        raise "postgresql install_extension: can't get extensions list\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stderr.empty?

        if stdout.include? extension
          Chef::Log.info("postgresql install: extension '#{extension}' already installed, skiping")
          return nil
        else
          stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, cluster_database, "CREATE EXTENSION \\\"#{extension}\\\" #{options.map { |t| t.join(' ') }.join(' ')}")
          raise "postgresql install_extension: can't install extension #{extension}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stdout.include?("CREATE EXTENSION\n")
          Chef::Log.info("postgresql install_extension: extension '#{extension}' installed")
        end
      end

      def pgxn_install_extension(cluster_version, cluster_name, params, options)
        pgxn_status = Mixlib::ShellOut.new("pgxn install '#{params[:name]}'='#{params[:version]}' --sudo --#{params[:stage]}")
        pgxn_status.run_command

        stdout, stderr = exec_in_pg_cluster(cluster_version, cluster_name, params[:db], 'SELECT extname FROM pg_extension')
        raise "postgresql install_extension: can't get extensions list\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" unless stderr.empty?

        if stdout.include? params[:name].downcase
          Chef::Log.info("postgresql install: extension '#{params[:name]}' already installed, skipping")
          return nil
        else
          pgxn_status = Mixlib::ShellOut.new("sudo -u postgres pgxn load '#{params[:name]}'='#{params[:version]}' -d #{params[:db]} --#{params[:stage]}  #{options.map { |t| t.join(' ') }.join(' ')}")
          pgxn_status.run_command
          raise "postgresql install_extension: can't install extension #{params[:name]}\nSTDOUT: #{pgxn_status.stdout}\nSTDERR: #{pgxn_status.stderr}" unless pgxn_status.stdout.include?('CREATE EXTENSION')
          Chef::Log.info("postgresql install_extension: extension '#{params[:name]}' installed")
        end
      end

      def configuration_hacks(configuration, cluster_version)
        configuration['unix_socket_directory'] ||= '/var/run/postgresql' if cluster_version.to_f < 9.3
        configuration['unix_socket_directories'] ||= '/var/run/postgresql' if cluster_version.to_f >= 9.3
        configuration.delete('wal_receiver_status_interval') if cluster_version.to_f < 9.1
        configuration.delete('hot_standby_feedback') if cluster_version.to_f < 9.1
      end

      def cloud_backup_configuration_hacks(configuration, cluster_name, cluster_version, wal_e_bin)
        configuration['archive_command'] = "envdir /etc/wal-e.d/#{cluster_name}-#{cluster_version}/env/ #{wal_e_bin} wal-push %p"
      end

      def params_validation(provider, credentials)
        case provider
        when 's3'
          required_params = [:AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY, :WALE_S3_PREFIX]
        when 'swift'
          required_params = [:SWIFT_AUTHURL, :SWIFT_TENANT, :SWIFT_USER, :SWIFT_PASSWORD, :WALE_SWIFT_PREFIX]
        when 'azure'
          required_params = [:WABS_ACCOUNT_NAME, :WABS_ACCESS_KEY, :WALE_WABS_PREFIX]
        end

        required_params - credentials.keys.map { |key| key.upcase.to_sym }
      end
    end
  end
end
