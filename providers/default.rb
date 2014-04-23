#
# Cookbook Name:: postgresql
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

action :create do

  configuration          = Chef::Mixin::DeepMerge.merge(node['postgresql']['defaults']['server'].to_hash, new_resource.configuration)
  hba_configuration      = node['postgresql']['defaults']['hba_configuration'] | new_resource.hba_configuration
  ident_configuration    = node['postgresql']['defaults']['ident_configuration'] | new_resource.ident_configuration

  cluster_name           = new_resource.name
  cluster_version        = configuration['version']
  service_name           = "postgresql_#{cluster_version}_#{cluster_name}"

  replication_file       = "/var/lib/postgresql/#{configuration[:version]}/#{cluster_name}/recovery.conf"
  replication            = new_resource.replication
  advanced_options       = new_resource.advanced_options

  cluster_options        = Mash.new(new_resource.cluster_create_options)

  parsed_cluster_options = []

  %w(locale lc-collate lc-ctype lc-messages lc-monetary lc-numeric lc-time).each do |option|
    parsed_cluster_options << "--#{option} #{cluster_options[:locale]}" if cluster_options[option]
  end

  # Locale hack
  if new_resource.cluster_create_options.key?('locale') && !new_resource.cluster_create_options['locale'].empty?
    system_lang = ENV['LANG']
    ENV['LANG'] = new_resource.cluster_create_options['locale']
  end

  # Install packages
  %W(postgresql-#{configuration["version"]} postgresql-server-dev-all).each do |pkg|
    package pkg
  end

  # Return locale
  if new_resource.cluster_create_options.key?('locale') && !new_resource.cluster_create_options['locale'].empty?
    ENV['LANG'] = system_lang
  end

  # Create postgresql cluster
  execute 'Exec pg_createcluster' do
    command "pg_createcluster #{parsed_cluster_options.join(' ')} #{cluster_version} #{cluster_name}"
    not_if { ::File.exist?("/etc/postgresql/#{cluster_version}/#{cluster_name}/postgresql.conf") }
  end

  postgresql_service = service service_name do
    action :nothing
    start_command "pg_ctlcluster #{cluster_version} #{cluster_name} start"
    stop_command "pg_ctlcluster #{cluster_version} #{cluster_name} stop"
    reload_command "pg_ctlcluster #{cluster_version} #{cluster_name} reload"
    restart_command "pg_ctlcluster #{cluster_version} #{cluster_name} restart"
    status_command "su -c '/usr/lib/postgresql/#{cluster_version}/bin/pg_ctl \
 -D /var/lib/postgresql/#{cluster_version}/#{cluster_name} status' postgres"
    supports status: true, restart: true, reload: true
    notifies :create, 'ruby_block[set_success_mark]', :delayed
  end

  ruby_block 'set_success_mark' do
    action :nothing
    block do
      node.normal['postgresql'][cluster_version][cluster_name]['success_at_least_once'] = true
    end
  end

  ruby_block 'restart_service' do
    action :nothing
    block do
      if need_to_restart(cluster_version, cluster_name, advanced_options, node)
        run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :restart, self))
      else
        run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :reload, self))
      end
    end
  end

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/postgresql.conf" do
    source 'postgresql.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: configuration, cluster_name: cluster_name
    cookbook new_resource.cookbook
    notifies :create, 'ruby_block[restart_service]', :delayed
  end

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/pg_hba.conf" do
    source 'pg_hba.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: hba_configuration
    cookbook new_resource.cookbook
    notifies :create, 'ruby_block[restart_service]', :delayed
  end

  template "/etc/postgresql/#{cluster_version}/#{cluster_name}/pg_ident.conf" do
    source 'pg_hba.conf.erb'
    owner 'postgres'
    group 'postgres'
    mode 0644
    variables configuration: ident_configuration
    cookbook new_resource.cookbook
    notifies :create, 'ruby_block[restart_service]', :delayed
  end

  if replication.empty?

    file replication_file do
      action :delete
      notifies :create, 'ruby_block[restart_service]', :delayed
    end

  else

    template "/var/lib/postgresql/#{cluster_version}/#{cluster_name}/recovery.conf" do
      source 'recovery.conf.erb'
      owner 'postgres'
      group 'postgres'
      mode 0644
      variables replication: replication
      cookbook new_resource.cookbook
      notifies :create, 'ruby_block[restart_service]', :delayed
    end

  end

  ruby_block 'start_service' do
    block do
      run_context.notifies_delayed(Chef::Resource::Notification.new(postgresql_service, :start, self))
    end
    not_if { pg_running?(cluster_version, cluster_name) }
  end

end
