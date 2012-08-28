#
# Cookbook Name:: postgresql
# Recipe:: pgbouncer
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

include_recipe "postgresql::client"

node["postgresql"]["pgbouncer"]["pkg"].each do |pkg|
  package pkg do
    action :install
  end
end

template node["postgresql"]["pgbouncer"]["pgbouncer_config"] do
  source "pgbouncer.ini.erb"
  owner "postgres"
  group "postgres"
  mode 0640
end

template node["postgresql"]["pgbouncer"]["auth"]["auth_file"] do
  source "userlist.txt.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

template "/etc/default/pgbouncer" do
  source "defaults_pgbouncer.erb"
end

service "pgbouncer" do
  supports :status => true, :restart => true, :reload => true, :start => true, :stop => true
  action [ :enable, :start ]
  subscribes :reload, resources(:template => node[:postgresql][:pgbouncer][:pgbouncer_config] ), :delayed
  subscribes :reload, resources(:template => node[:postgresql][:pgbouncer][:auth][:auth_file] ), :delayed
end
