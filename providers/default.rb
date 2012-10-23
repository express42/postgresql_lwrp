#
# Cookbook Name:: postgresql
# Provider:: default
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) LLC 2012 Express 42
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

action :create do
  cluster_databag = new_resource.databag

  if cluster_databag
    begin
      cluster_users = data_bag_item(cluster_databag, 'users')['users']
    rescue
      cluster_users = {}
    end

    begin
      cluster_databases = data_bag_item(cluster_databag, 'databases')['databases']
    rescue
      cluster_databases = {}
    end
  end

  configuration       = Chef::Mixin::DeepMerge.merge(node.postgresql.defaults.server.to_hash, new_resource.configuration)
  hba_configuration   = node.postgresql.defaults.hba_configuration | new_resource.hba_configuration
  ident_configuration = node.postgresql.defaults.ident_configuration | new_resource.ident_configuration

  %W{postgresql-#{configuration[:version]} postgresql-server-dev-all}.each do |pkg|
    package pkg do
      action :nothing
    end.run_action(:install)
  end

  create_cluster(new_resource.name, configuration, hba_configuration, ident_configuration, new_resource.replication,  new_resource.cluster_create_options)

  if cluster_databag

    cluster_users.each_pair do |cluster_user, user_options|
      create_user(cluster_user, configuration, user_options["options"])
    end

    cluster_databases.each_pair do |cluster_database, database_options|
      create_database(cluster_database, configuration, database_options["options"])
    end

  end

end

private

def create_cluster(cluster_name, configuration, hba_configuration, ident_configuration, replication, cluster_options)
  
  parsed_cluster_options = []
  cluster_options.each do |option|
    parsed_cluster_options << "--locale #{option[:locale]}" if option[:locale]
    parsed_cluster_options << "--lc-collate #{option[:'lc-collate']}" if option[:'lc-collate']
    parsed_cluster_options << "--lc-ctype #{option[:'lc-ctype']}" if option[:'lc-ctype']
    parsed_cluster_options << "--lc-messages #{option[:'lc-messages']}" if option[:'lc-messages']
    parsed_cluster_options << "--lc-monetary #{option[:'lc-monetary']}" if option[:'lc-monetary']
    parsed_cluster_options << "--lc-numeric #{option[:'lc-numeric']}" if option[:'lc-numeric']
    parsed_cluster_options << "--lc-time #{option[:'lc-time']}" if option[:'lc-time']
  end

  if ::File.exist?("/etc/postgresql/#{configuration[:version]}/#{cluster_name}/postgresql.conf")
    Chef::Log.info("postgresql_cluster:create - cluster #{configuration[:version]}/#{cluster_name} already exists, skiping")
  else

    io_output = IO.popen( "pg_createcluster #{parsed_cluster_options.join(' ')} #{configuration[:version]} #{cluster_name}" )
    string_output=io_output.readlines.join
    io_output.close

    if $?.exitstatus != 0
      raise "pg_createcluster #{parsed_cluster_options.join(' ')} #{configuration[:version]} #{cluster_name} - returned #{$?.exitstatus}, expected 0"
    else
      Chef::Log.info( "postgresql_cluster:create - cluster #{configuration[:version]}/#{cluster_name} created" )
      @new_resource.updated_by_last_action(true)
    end
  end

  configuration_template = template "/etc/postgresql/#{configuration[:version]}/#{cluster_name}/postgresql.conf" do
    action :nothing
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    variables :configuration => configuration, :cluster_name => cluster_name
    if new_resource.cookbook
      cookbook new_resource.cookbook
    else
      cookbook "postgresql"
    end
  end

  hba_template = template "/etc/postgresql/#{configuration[:version]}/#{cluster_name}/pg_hba.conf" do
    action :nothing
    source "pg_hba.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    variables :configuration => hba_configuration, :cluster_name => cluster_name
    if new_resource.cookbook
      cookbook new_resource.cookbook
    else
      cookbook "postgresql"
    end
  end

  ident_template = template "/etc/postgresql/#{configuration[:version]}/#{cluster_name}/pg_ident.conf" do
    action :nothing
    source "pg_hba.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    variables :configuration => ident_configuration, :cluster_name => cluster_name
    if new_resource.cookbook
      cookbook new_resource.cookbook
    else
      cookbook "postgresql"
    end
  end

  replication_template = template "/var/lib/postgresql/#{configuration[:version]}/#{cluster_name}/recovery.conf" do
    action :nothing
    source "recovery.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0644
    variables :replication => replication
    if new_resource.cookbook
      cookbook new_resource.cookbook
    else
      cookbook "postgresql"
    end
  end

  postgresql_service = service "postgresql" do
    status_command "su -c '/usr/lib/postgresql/#{configuration[:version]}/bin/pg_ctl \
 -D /var/lib/postgresql/#{configuration[:version]}/#{cluster_name} status' postgres"
    supports :status => true, :restart => true, :reload => true
    action :enable
  end

  configuration_template.run_action(:create)
  hba_template.run_action(:create)
  ident_template.run_action(:create)

  replication_file = "/var/lib/postgresql/#{configuration[:version]}/#{cluster_name}/recovery.conf"

  if replication.empty?
    ::File.exist?( replication_file ) and ::File.unlink( replication_file )
  else
    replication_template.run_action(:create)
  end

  postgresql_service.run_action(:start)

  if configuration_template.updated_by_last_action? or hba_template.updated_by_last_action? or ident_template.updated_by_last_action?
    postgresql_service.run_action(:reload)
    @new_resource.updated_by_last_action(true)
  end

end

def create_database(cluster_database, configuration, database_options)

  parsed_database_options = []

  if cluster_database
    parsed_database_options << "--locale=#{database_options['locale']}" if database_options['locale']
    parsed_database_options << "--lc-collate=#{database_options['lc-collate']}" if database_options['lc-collate']
    parsed_database_options << "--lc-ctype=#{database_options['lc-ctype']}" if database_options['lc-ctype']
    parsed_database_options << "--owner=#{database_options['owner']}" if database_options['owner']
    parsed_database_options << "--template=#{database_options['template']}" if database_options['template']
    parsed_database_options << "--tablespace=#{database_options['tablespace']}" if database_options['tablespace']
  end

  io_output = IO.popen("echo 'SELECT datname FROM pg_database;' | su -c 'psql -t -A -p #{configuration["connection"]["port"]}' postgres")
  current_databases_list = io_output.readlines.map { |line| line.chop }
  io_output.close

  raise "postgresql_database:create - can't get database list" if $?.exitstatus !=0

  if current_databases_list.include? cluster_database
    Chef::Log.info("postgresql_database:create - database '#{cluster_database}' already exists, skiping")
  else
    io_output =IO.popen("su -c 'createdb #{parsed_database_options.join(' ')} #{cluster_database} -p #{configuration["connection"]["port"]}' postgres")
    io_output.close
    raise "postgresql_database:create - can't create database #{cluster_database}" if $?.exitstatus !=0
    Chef::Log.info("postgresql_database:create - database '#{cluster_database}' created")
  end
end

def create_user(cluster_user, configuration, user_options)
  
  parsed_user_options = []

  if user_options
    parsed_user_options << "REPLICATION" if user_options["replication"]  =~ /\A(true|yes)\Z/i
    parsed_user_options << "SUPERUSER" if user_options["superuser"] =~ /\A(true|yes)\Z/i
    parsed_user_options << "UNENCRYPTED PASSWORD '#{user_options["password"]}'" if user_options["password"]
  end

  io_output = IO.popen("echo 'SELECT usename FROM pg_user;' | su -c 'psql -t -A' postgres")
  current_users_list = io_output.readlines.map { |line| line.chop }
  io_output.close
  raise "postgresql_user:create - can't get users list" if $?.exitstatus !=0

  if current_users_list.include? cluster_user
    Chef::Log.info("postgresql_user:create - user '#{cluster_user}' already exists, skiping")
  else
    io_output =IO.popen("echo \"CREATE USER #{cluster_user} #{parsed_user_options.join(' ')};\" | su -c 'psql -t -A' postgres")
    create_response = io_output.readlines
    io_output.close
    if not create_response.include?("CREATE ROLE\n")
      raise "postgresql_user:create - can't create user #{cluster_user}"
    end
    Chef::Log.info("postgresql_user:create - user '#{cluster_user}' created")
  end
end
