#
# Cookbook Name:: postgresql_lwrp
# Resource:: cloud_backup
#
# Author:: Kirill Kouznetsov (agon.smith@gmail.com)
#
# Copyright (C) 2014 LLC Express 42
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

provides :postgresql_cloud_backup
resource_name :postgresql_cloud_backup

default_action :schedule

property :utility, String,
         default: 'wal-e',
         equal_to: %w(wal-e wal_e wal-g wal_g)
property :in_version, String, required: true
property :in_cluster, String, required: true
property :parameters, Hash, required: true

# Crontab command prefix to use with wal-e, e.g. for speed limit by trickle
# like `trickle -s -u 1024 envdir /etc/wal-e.d/...`
property :command_prefix, String, required: false
property :full_backup_time, Hash,
         default: {
           minute: '0',
           hour: '3',
           day: '*',
           month: '*',
           weekday: '*',
         }
property :retain, Integer, required: false

action_class do
  include Chef::Postgresql::Helpers

  def install_wal_e
    wal_e_attributes = node['postgresql']['cloud_backup']['wal_e']

    python_runtime '3' do
      provider :system
      options package_name: 'python3'
    end

    python_virtualenv wal_e_attributes['path'] do
      python '3'
    end

    python_package wal_e_attributes['pypi_packages'] do
      virtualenv wal_e_attributes['path']
    end

    wal_e_repo = wal_e_attributes['github_repo']
    wal_e_version = wal_e_attributes['version']
    case wal_e_attributes['install_source']
    when 'github'
      archive_url = "#{wal_e_repo}/archive/#{wal_e_version}.zip"
      python_package 'wal-e' do
        package_name archive_url
        virtualenv wal_e_attributes['path']
      end
    when 'pypi'
      python_package 'wal-e' do
        version wal_e_version
        virtualenv wal_e_attributes['path']
      end
    end

    template 'postgresql cloud backup' do
      path "#{wal_e_attributes['path']}/bin/postgresql_cloud_backup_helper.sh"
      source 'postgresql_cloud_backup_helper.sh.erb'
      cookbook 'postgresql_lwrp'
      mode '0755'
      variables(
        wal_e_bin: wal_e_attributes['bin']
      )
    end
  end

  def install_wal_g
    remote_file 'wal-g' do
      path "#{Chef::Config[:file_cache_path]}/wal-g.linux-amd64.tar.gz"
      owner 'root'
      group 'root'
      mode '0644'
      source node['postgresql']['cloud_backup']['wal_g']['url']
      checksum node['postgresql']['cloud_backup']['wal_g']['checksum']
    end

    dirname = ::File.dirname node['postgresql']['cloud_backup']['wal_g']['bin']
    bash 'untar wal-g' do
      code "tar -xzf #{Chef::Config[:file_cache_path]}/wal-g.linux-amd64.tar.gz -C #{dirname}"
      action :nothing
      subscribes :run, 'remote_file[wal-g]', :immediately
    end
  end
end

action :install do
  backup_utility = new_resource.utility.sub('_', '-')

  package node['postgresql']['cloud_backup'][backup_utility.sub('-', '_')]['packages'] +
          ['daemontools']

  case backup_utility
  when 'wal-e'
    install_wal_e
  when 'wal-g'
    install_wal_g
  end
end

action :schedule do
  action_install

  postgresql_version       = new_resource.in_version
  postgresql_instance_name = new_resource.in_cluster
  postgresql_name_version  = "#{postgresql_instance_name}-#{postgresql_version}"
  postgresql_path          = "/var/lib/postgresql/#{postgresql_version}/#{postgresql_instance_name}"

  backup_utility     = new_resource.utility.sub('_', '-')
  backup_utility_bin = node['postgresql']['cloud_backup'][backup_utility.sub('-', '_')]['bin']
  command_prefix     = new_resource.command_prefix
  envdir_params      = new_resource.parameters
  full_backup_time   = new_resource.full_backup_time

  # Add libpq PGPORT variable to envdir_params
  envdir_params['PGPORT'] = get_pg_port(postgresql_version, postgresql_instance_name).to_s

  # wal-g needs a default PGHOST variable to connect via UNIX socket
  if backup_utility == 'wal-g' &&
     !envdir_params.key?('PGHOST')
    envdir_params['PGHOST'] = '/var/run/postgresql'
    envdir_params['PATH'] = '/bin:/sbin:/usr/bin:/usr/sbin'
  end

  # Create environment directory
  directory "/etc/#{backup_utility}.d/#{postgresql_name_version}/env" do
    recursive true
    mode '0750'
    owner 'root'
    group 'postgres'
  end

  if envdir_params.key? 'tmpdir'
    # We may use custom temp dir
    directory "#{backup_utility.upcase} temp directory" do
      path envdir_params['tmpdir']
      recursive true
      mode '0750'
      owner 'postgres'
      group 'postgres'
    end
  end

  # Create all param files in directory
  envdir_params.each do |key, val|
    file "/etc/#{backup_utility}.d/#{postgresql_name_version}/env/#{key.upcase}" do
      mode '0640'
      owner 'root'
      group 'postgres'
      content val
      sensitive true
      backup false
    end
  end

  # Remove unused
  ruby_block 'Remove unused variables' do
    block do
      unused_variables = ::Dir["/etc/#{backup_utility}.d/#{postgresql_name_version}/env/*"] - envdir_params.keys.map { |key| "/etc/#{backup_utility}.d/#{postgresql_name_version}/env/#{key.upcase}" }
      unused_variables.each { |var| ::File.delete var }
    end
  end

  # Create crontask via cron cookbook
  cron_d "backup_postgresql_cluster_#{postgresql_name_version.sub('.', '-')}" do
    command "#{command_prefix} envdir /etc/#{backup_utility}.d/#{postgresql_name_version}/env #{backup_utility_bin} backup-push #{postgresql_path}"
    user 'postgres'
    minute full_backup_time[:minute]
    hour full_backup_time[:hour]
    day full_backup_time[:day]
    month full_backup_time[:month]
    weekday full_backup_time[:weekday]
  end

  if new_resource.retain
    num_to_retain = new_resource.retain
    cron_d "remove_old_backups_postgresql_cluster_#{postgresql_name_version.sub('.', '-')}" do
      command "#{command_prefix} envdir /etc/#{backup_utility}.d/#{postgresql_name_version}/env #{backup_utility_bin} delete --confirm retain #{num_to_retain}"
      user 'postgres'
      minute full_backup_time[:minute]
      hour full_backup_time[:hour]
      day full_backup_time[:day]
      month full_backup_time[:month]
      weekday full_backup_time[:weekday]
    end
  else
    cron_d "remove_old_backups_postgresql_cluster_#{postgresql_name_version.sub('.', '-')}" do
      action :delete
    end
  end
end
