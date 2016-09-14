#
# Cookbook Name:: postgresql_lwrp
# Provider:: default
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

use_inline_resources

include Chef::Postgresql::Helpers

provides :postgresql if defined? provides

action :create do
  configuration            = Chef::Mixin::DeepMerge.merge(node['postgresql']['defaults']['server']['configuration'].to_hash, new_resource.configuration)
  hba_configuration        = node['postgresql']['defaults']['server']['hba_configuration'] | new_resource.hba_configuration
  ident_configuration      = node['postgresql']['defaults']['server']['ident_configuration'] | new_resource.ident_configuration

  cluster_name             = new_resource.name
  cluster_version          = (!new_resource.cluster_version.empty? && new_resource.cluster_version) || node['postgresql']['defaults']['server']['version']
  service_name             = "postgresql_#{cluster_version}_#{cluster_name}"

  allow_restart_cluster    = new_resource.allow_restart_cluster

  replication              = new_resource.replication
  replication_file         = "/var/lib/postgresql/#{cluster_version}/#{cluster_name}/recovery.conf"
  replication_start_slave  = new_resource.replication_start_slave
  replication_initial_copy = new_resource.replication_initial_copy

  wal_e_bin               = node['postgresql']['cloud_backup']['wal_e_bin']

  cluster_options          = Mash.new(new_resource.cluster_create_options)
  parsed_cluster_options   = []

  first_time               = pg_installed?("postgresql-#{cluster_version}")

  %w(locale lc-collate lc-ctype lc-messages lc-monetary lc-numeric lc-time).each do |option|
    parsed_cluster_options << "--#{option} #{cluster_options[:locale]}" if cluster_options[option]
  end

  # Locale hack
  if new_resource.cluster_create_options.key?('locale') && !new_resource.cluster_create_options['locale'].empty?
    system_lang = ENV['LANG']
    ENV['LANG'] = new_resource.cluster_create_options['locale']
  end

  # Configuration hacks
  configuration_hacks(configuration, cluster_version)

  # Backups hacks
  if configuration['archive_command'] == 'cloud_auto'.downcase.to_sym
    cloud_backup_configuration_hacks(configuration, cluster_name, cluster_version, wal_e_bin)
  end

  # Install postgresql-common package
  package 'postgresql-common'

  file '/etc/postgresql-common/createcluster.conf' do
    content "create_main_cluster = false\n"
    only_if { cluster_version.to_f >= 9.2 }
  end

  # Install postgresql server packages
  %W(postgresql-#{cluster_version} postgresql-contrib-#{cluster_version} postgresql-server-dev-#{cluster_version}).each do |pkg|
    package pkg
  end

  # Install pgxn client to download custom extensions
  package 'pgxnclient'
  package 'build-essential'

  # Return locale
  if new_resource.cluster_create_options.key?('locale') && !new_resource.cluster_create_options['locale'].empty?
    ENV['LANG'] = system_lang
  end

  # Systemd not working with cluster names with dashes
  # see http://comments.gmane.org/gmane.comp.db.postgresql.debian/346
  if systemd_used? && cluster_name.include?('-')
    fail "Sorry, systemd not support cluster names with dashes ('-'), use underscore ('_') instead"
  end

  # Create postgresql cluster directories
  %W(/etc/postgresql /etc/postgresql/#{cluster_version} /etc/postgresql/#{cluster_version}/#{cluster_name}).each do |dir|
    directory dir do
      owner 'postgres'
      group 'postgres'
    end
  end

  %W(/var/lib/postgresql /var/lib/postgresql/#{cluster_version}).each do |dir|
    directory dir do
      owner 'postgres'
      group 'postgres'
    end
  end

  directory "/var/lib/postgresql/#{cluster_version}/#{cluster_name}" do
    mode '0700'
    owner 'postgres'
    group 'postgres'
  end

  # Exec pg_cluster create
  execute 'Exec pg_createcluster' do
    command "pg_createcluster #{parsed_cluster_options.join(' ')} #{cluster_version} #{cluster_name}"
    not_if { ::File.exist?("/etc/postgresql/#{cluster_version}/#{cluster_name}/postgresql.conf") || !replication.empty? }
  end

  # Define postgresql service
  postgresql_service = service service_name do
    action :nothing
    provider Chef::Provider::Service::Simple
    start_command "pg_ctlcluster #{cluster_version} #{cluster_name} start"
    stop_command "pg_ctlcluster #{cluster_version} #{cluster_name} stop"
    reload_command "pg_ctlcluster #{cluster_version} #{cluster_name} reload"
    restart_command "pg_ctlcluster #{cluster_version} #{cluster_name} restart"
    status_command "su -c '/usr/lib/postgresql/#{cluster_version}/bin/pg_ctl \
 -D /var/lib/postgresql/#{cluster_version}/#{cluster_name} status' postgres"
    supports status: true, restart: true, reload: true
  end

  # Ruby block for postgresql smart restart
  ruby_block "restart_service_#{service_name}" do
    action :nothing
    block do
      if !replication.empty? && !replication_start_slave
        run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :reload, self))
      elsif need_to_restart?(allow_restart_cluster.to_sym, first_time)
        run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :restart, self))
      else
        run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :reload, self))
      end
    end
  end

  # Configuration templates

  main_configuration = configuration.dup
  main_configuration.delete('ssl_cert_file') if cluster_version.to_f < 9.2
  main_configuration.delete('ssl_key_file') if cluster_version.to_f < 9.2
  main_configuration.delete("checkpoint_segments") if cluster_version.to_f > 9.4

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/postgresql.conf" do
    source 'postgresql.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: main_configuration, cluster_name: cluster_name, cluster_version: cluster_version
    cookbook new_resource.cookbook
    notifies :create, "ruby_block[restart_service_#{service_name}]", :delayed
  end

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/pg_hba.conf" do
    source 'pg_hba.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: hba_configuration
    cookbook new_resource.cookbook
    notifies :create, "ruby_block[restart_service_#{service_name}]", :delayed
  end

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/pg_ident.conf" do
    source 'pg_ident.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: ident_configuration
    cookbook new_resource.cookbook
    notifies :create, "ruby_block[restart_service_#{service_name}]", :delayed
  end

  file "/etc/postgresql/#{cluster_version}/#{cluster_name}/start.conf" do
    content "auto\n"
  end

  # Replication
  if !replication.empty?

    if replication_initial_copy
      pg_basebackup_path = "/usr/lib/postgresql/#{cluster_version}/bin/pg_basebackup"
      pg_data_directory = "/var/lib/postgresql/#{cluster_version}/#{cluster_name}"

      BASEBACKUP_PARAMS = {
        'host'     => '-h',
        'port'     => '-p',
        'user'     => '-U',
        'password' => '-W'
      }

      conninfo_hash = Hash[*replication[:primary_conninfo].scan(/\w+=[^\s]+/).map { |x| x.split('=', 2) }.flatten]

      basebackup_conninfo_hash = conninfo_hash.map do |key, val|
        "#{BASEBACKUP_PARAMS[key.to_s]} #{val}" if BASEBACKUP_PARAMS[key.to_s]
      end.compact

      execute 'Make basebackup' do
        command "#{pg_basebackup_path} -D #{pg_data_directory} -F p -x -c fast #{basebackup_conninfo_hash.join(' ')}"
        user 'postgres'
        not_if { ::File.exist?("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/base") }
        timeout 604_800
      end
    end

    link "/var/lib/postgresql/#{cluster_version}/#{cluster_name}/server.key" do
      to configuration['ssl_key_file']
      not_if { cluster_version.to_f > 9.1 && ::File.exist?("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/server.key") }
    end

    link "/var/lib/postgresql/#{cluster_version}/#{cluster_name}/server.crt" do
      to configuration['ssl_cert_file']
      not_if { cluster_version.to_f > 9.1 && ::File.exist?("/var/lib/postgresql/#{cluster_version}/#{cluster_name}/server.crt") }
    end

    template "/var/lib/postgresql/#{cluster_version}/#{cluster_name}/recovery.conf" do
      source 'recovery.conf.erb'
      owner 'postgres'
      group 'postgres'
      mode 0644
      variables replication: replication
      cookbook new_resource.cookbook
      notifies :create, "ruby_block[restart_service_#{service_name}]", :delayed
    end

  else

    file replication_file do
      action :delete
      notifies :create, "ruby_block[restart_service_#{service_name}]", :delayed
    end
  end

  # Start postgresql
  ruby_block "start_service_#{service_name}]" do
    block do
      run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :start, self))
    end
    not_if { pg_running?(cluster_version, cluster_name) || (!replication.empty? && !replication_start_slave) }
  end
end
