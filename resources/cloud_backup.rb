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

include Chef::Postgresql::Helpers

provides :postgresql_cloud_backup
resource_name :postgresql_cloud_backup

default_action :schedule

property :in_version, String, required: true
property :in_cluster, String, required: true
property :protocol, String,
         required: true,
         callbacks: {
           'is not allowed! Allowed providers: s3, swift or  azure' => proc do |value|
             !value.to_sym.match(/^(s3|swift|azure)$/).nil?
           end,
         }
property :parameters, Hash, required: true

# Crontab command prefix to use with wal-e, e.g. for speed limit by trickle
# like `trickle -s -u 1024 envdir /etc/wal-e.d/...`
property :command_prefix, String, required: false
property :full_backup_time, Hash,
         default: { minute: '0', hour: '3', day: '*', month: '*', weekday: '*' }
property :retain, Integer, required: false

action :schedule do
  postgresql_version       = new_resource.in_version
  postgresql_instance_name = new_resource.in_cluster
  postgresql_name_version  = "#{postgresql_instance_name}-#{postgresql_version}"
  postgresql_path          = "/var/lib/postgresql/#{postgresql_version}/#{postgresql_instance_name}"
  wal_e_bin                = node['postgresql']['cloud_backup']['wal_e_bin']
  command_prefix           = new_resource.command_prefix
  envdir_params            = new_resource.parameters
  full_backup_time         = new_resource.full_backup_time

  unsetted_required_params = params_validation(new_resource.protocol, envdir_params)
  raise "Key(s) '#{unsetted_required_params.join(', ')}' missing for protocol '#{new_resource.protocol}'" unless unsetted_required_params.empty?

  # Add libpq PGPORT variable to envdir_params
  envdir_params['PGPORT'] = get_pg_port(postgresql_version, postgresql_instance_name).to_s

  # Create wal-e root directory
  directory "/etc/wal-e.d/#{postgresql_name_version}/env" do
    recursive true
    mode '0750'
    owner 'root'
    group 'postgres'
  end

  if envdir_params.key? 'tmpdir'
    # We may use custom temp dir
    directory 'WAL-E temp directory' do
      path envdir_params['tmpdir']
      recursive true
      mode '0750'
      owner 'postgres'
      group 'postgres'
    end
  end

  # Create all param files in wal-e.d/env directory
  envdir_params.each do |key, val|
    file "/etc/wal-e.d/#{postgresql_name_version}/env/#{key.upcase}" do
      mode 0640
      owner 'root'
      group 'postgres'
      content val
      backup false
    end
  end

  # Remove unused
  ruby_block 'Remove unused variables' do
    block do
      unused_variables = ::Dir["/etc/wal-e.d/#{postgresql_name_version}/env/*"] - envdir_params.keys.map { |key| "/etc/wal-e.d/#{postgresql_name_version}/env/#{key.upcase}" }
      unused_variables.each { |var| ::File.delete var }
    end
  end

  # Create crontask via cron cookbook
  cron_d "backup_postgresql_cluster_#{postgresql_name_version.sub('.', '-')}" do
    command "#{command_prefix} envdir /etc/wal-e.d/#{postgresql_name_version}/env #{wal_e_bin} backup-push #{postgresql_path}"
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
      command "#{command_prefix} envdir /etc/wal-e.d/#{postgresql_name_version}/env #{wal_e_bin} delete --confirm retain #{num_to_retain}"
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
